-- =============================================================
-- SHOW ME THE BIBLE - Supabase Schema
-- Supabase Dashboard > SQL Editor 에서 순서대로 실행하세요
-- =============================================================

-- ① ENUM 타입 정의
CREATE TYPE user_role AS ENUM ('admin', 'contestant');
CREATE TYPE session_status AS ENUM ('waiting', 'round_active', 'round_locked', 'finished');

-- ② 프로필 테이블
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    nickname TEXT NOT NULL,
    role user_role DEFAULT 'contestant' NOT NULL,
    total_score FLOAT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ③ 성경 구절 문제 은행 (개역개정 기준)
CREATE TABLE public.verses_pool (
    id SERIAL PRIMARY KEY,
    reference TEXT NOT NULL,        -- 예: "창세기 1:1"
    content TEXT NOT NULL,          -- 개역개정 정답 본문
    difficulty INTEGER DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    created_by UUID REFERENCES public.profiles(id)
);

-- ④ 게임 세션
CREATE TABLE public.game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status session_status DEFAULT 'waiting' NOT NULL,
    current_round INTEGER DEFAULT 1 NOT NULL CHECK (current_round BETWEEN 1 AND 11),
    total_rounds INTEGER DEFAULT 11 NOT NULL,
    is_paused BOOLEAN DEFAULT FALSE,
    stt_enabled BOOLEAN DEFAULT TRUE NOT NULL,
    created_by UUID REFERENCES public.profiles(id),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ⑤ 세션별 라운드 문제 매칭
CREATE TABLE public.session_questions (
    id SERIAL PRIMARY KEY,
    session_id UUID REFERENCES public.game_sessions(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL CHECK (round_number BETWEEN 1 AND 11),
    verse_id INTEGER REFERENCES public.verses_pool(id),
    UNIQUE(session_id, round_number)
);

-- ⑥ 참가자 제출 및 실시간 현황
CREATE TABLE public.submissions (
    id SERIAL PRIMARY KEY,
    session_id UUID REFERENCES public.game_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id),
    round_number INTEGER NOT NULL CHECK (round_number BETWEEN 1 AND 11),
    input_text TEXT DEFAULT '',
    progress_rate FLOAT DEFAULT 0 CHECK (progress_rate BETWEEN 0 AND 1),
    accuracy_score FLOAT DEFAULT 0 CHECK (accuracy_score BETWEEN 0 AND 100),
    is_final BOOLEAN DEFAULT FALSE,
    submitted_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(session_id, user_id, round_number)
);

-- ⑦ updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER submissions_updated_at
BEFORE UPDATE ON public.submissions
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ⑧ 신규 사용자 프로필 자동 생성 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nickname', SPLIT_PART(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ⑨ 관리자 라운드 전환 RPC 함수 (미제출 답안 일괄 확정)
CREATE OR REPLACE FUNCTION public.admin_advance_round(p_session_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_current_round INTEGER;
  v_total_rounds INTEGER;
  v_new_status session_status;
BEGIN
  -- 관리자 권한 확인
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN jsonb_build_object('error', 'Unauthorized');
  END IF;

  SELECT current_round, total_rounds
  INTO v_current_round, v_total_rounds
  FROM public.game_sessions WHERE id = p_session_id;

  -- 미제출 답안 일괄 확정 (현재 내용 그대로)
  UPDATE public.submissions
  SET is_final = TRUE, submitted_at = NOW()
  WHERE session_id = p_session_id
    AND round_number = v_current_round
    AND is_final = FALSE;

  -- 상태 전이
  IF v_current_round >= v_total_rounds THEN
    v_new_status := 'finished';
    UPDATE public.game_sessions
    SET status = v_new_status,
        finished_at = NOW()
    WHERE id = p_session_id;
  ELSE
    v_new_status := 'round_locked';
    UPDATE public.game_sessions
    SET status = v_new_status,
        current_round = v_current_round + 1
    WHERE id = p_session_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'new_status', v_new_status::text);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ⑩ 관리자 세션 시작 RPC
CREATE OR REPLACE FUNCTION public.admin_start_session(p_session_id UUID)
RETURNS JSONB AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN jsonb_build_object('error', 'Unauthorized');
  END IF;

  UPDATE public.game_sessions
  SET status = 'round_active',
      current_round = 1,
      started_at = NOW()
  WHERE id = p_session_id AND status = 'waiting';

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ⑪ 관리자 라운드 활성화 RPC (round_locked → round_active)
CREATE OR REPLACE FUNCTION public.admin_activate_round(p_session_id UUID, p_verse_id INTEGER)
RETURNS JSONB AS $$
DECLARE
  v_current_round INTEGER;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN jsonb_build_object('error', 'Unauthorized');
  END IF;

  SELECT current_round INTO v_current_round
  FROM public.game_sessions WHERE id = p_session_id;

  -- 문제 등록 (이미 있으면 업데이트)
  INSERT INTO public.session_questions (session_id, round_number, verse_id)
  VALUES (p_session_id, v_current_round, p_verse_id)
  ON CONFLICT (session_id, round_number) DO UPDATE SET verse_id = p_verse_id;

  -- 세션 상태 활성화
  UPDATE public.game_sessions
  SET status = 'round_active'
  WHERE id = p_session_id AND status IN ('waiting', 'round_locked');

  RETURN jsonb_build_object('success', true, 'round', v_current_round);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
