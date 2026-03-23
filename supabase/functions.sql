-- ================================================================
-- SHOW ME THE BIBLE - Supabase RPC Functions
-- ================================================================
-- 이 파일의 SQL을 Supabase Dashboard > SQL Editor에서 실행하세요.

-- ----------------------------------------------------------------
-- 1. 세션 시작 (waiting → round_active)
-- ----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_start_session(UUID);
CREATE OR REPLACE FUNCTION admin_start_session(p_session_id UUID)
RETURNS void AS $$
BEGIN
  -- 관리자 권한 확인
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;

  UPDATE public.game_sessions
  SET
    status       = 'waiting',   -- 구절 선택 후 activate_round 호출 대기
    current_round = 1,
    started_at   = NOW()
  WHERE id = p_session_id
    AND status = 'waiting';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Session not found or already started';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------
-- 2. 라운드 활성화 (waiting/round_locked → round_active)
--    관리자가 구절을 선택하면 해당 라운드 시작
-- ----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_activate_round(UUID, INTEGER);
CREATE OR REPLACE FUNCTION admin_activate_round(
  p_session_id UUID,
  p_verse_id   INTEGER
)
RETURNS void AS $$
DECLARE
  v_current_round INTEGER;
BEGIN
  -- 관리자 권한 확인
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;

  SELECT current_round INTO v_current_round
  FROM public.game_sessions WHERE id = p_session_id;

  -- 구절 등록 (이미 있으면 무시)
  INSERT INTO public.session_questions (session_id, round_number, verse_id)
  VALUES (p_session_id, v_current_round, p_verse_id)
  ON CONFLICT (session_id, round_number) DO UPDATE
    SET verse_id = EXCLUDED.verse_id;

  -- 세션 상태를 round_active로 전환
  UPDATE public.game_sessions
  SET status = 'round_active'
  WHERE id = p_session_id
    AND status IN ('waiting', 'round_locked');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------
-- 3. 라운드 강제 전환 (round_active → round_locked / finished)
--    미제출 답안 일괄 확정 포함
-- ----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_advance_round(UUID);
CREATE OR REPLACE FUNCTION admin_advance_round(p_session_id UUID)
RETURNS void AS $$
DECLARE
  v_current_round INTEGER;
  v_total_rounds  INTEGER;
BEGIN
  -- 관리자 권한 확인
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;

  SELECT current_round, total_rounds
  INTO v_current_round, v_total_rounds
  FROM public.game_sessions WHERE id = p_session_id;

  -- ★ 미제출 답안 일괄 확정
  UPDATE public.submissions
  SET
    is_final     = TRUE,
    submitted_at = NOW()
  WHERE session_id   = p_session_id
    AND round_number = v_current_round
    AND is_final     = FALSE;

  -- ★ 세션 상태 전이
  IF v_current_round >= v_total_rounds THEN
    -- 마지막 라운드 → 종료
    UPDATE public.game_sessions
    SET
      status      = 'finished',
      finished_at = NOW()
    WHERE id = p_session_id;
  ELSE
    -- 중간 라운드 → 전환 대기 + 라운드 증가
    UPDATE public.game_sessions
    SET
      status        = 'round_locked',
      current_round = v_current_round + 1
    WHERE id = p_session_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------
-- 4. 일시 정지 / 재개
-- ----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_toggle_pause(UUID);
CREATE OR REPLACE FUNCTION admin_toggle_pause(p_session_id UUID)
RETURNS void AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;

  UPDATE public.game_sessions
  SET is_paused = NOT is_paused
  WHERE id = p_session_id AND status = 'round_active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
