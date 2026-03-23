-- =============================================================
-- SHOW ME THE BIBLE - RLS 보안 정책
-- schema.sql 실행 후 이 파일을 실행하세요
-- =============================================================

-- ① RLS 활성화
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verses_pool ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;

-- =============================================================
-- profiles 정책
-- =============================================================

-- 자신의 프로필 조회
CREATE POLICY "profiles_self_select" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- 관리자: 전체 프로필 조회 (리더보드용)
CREATE POLICY "profiles_admin_select" ON public.profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 자신의 프로필 수정 (nickname만)
CREATE POLICY "profiles_self_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 트리거에 의한 자동 INSERT (SECURITY DEFINER 함수가 처리)
CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================================
-- verses_pool 정책
-- =============================================================

-- 모든 인증된 유저는 구절 조회 가능 (참가자 화면 노출용)
CREATE POLICY "verses_read_all" ON public.verses_pool
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- 관리자만 구절 추가/수정/삭제 가능
CREATE POLICY "verses_admin_modify" ON public.verses_pool
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- =============================================================
-- game_sessions 정책
-- =============================================================

-- 모든 인증 유저: 세션 조회 (Realtime 구독용)
CREATE POLICY "sessions_read_all" ON public.game_sessions
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- 관리자만: 세션 생성
CREATE POLICY "sessions_admin_insert" ON public.game_sessions
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 관리자만: 세션 수정 (RPC 함수가 SECURITY DEFINER로 처리)
CREATE POLICY "sessions_admin_update" ON public.game_sessions
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 관리자만: 세션 삭제
CREATE POLICY "sessions_admin_delete" ON public.game_sessions
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- =============================================================
-- session_questions 정책 - ★ 문제 유출 방지 핵심
-- =============================================================

-- 참가자: current_round 이하의 구절만 조회 (단, verse_id의 content는 별도 조인 불가)
-- ※ 실제 verse content는 관리자가 활성화한 라운드 시작 시점에만 공개
CREATE POLICY "sq_contestant_select" ON public.session_questions
  FOR SELECT USING (
    -- 관리자는 항상 조회 가능
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR
    -- 참가자: 현재 라운드 이하만 조회 + 세션이 활성 상태
    EXISTS (
      SELECT 1 FROM public.game_sessions gs
      WHERE gs.id = session_id
        AND gs.current_round >= round_number
        AND gs.status != 'waiting'
    )
  );

-- 관리자만: 문제 등록 (RPC 함수 처리)
CREATE POLICY "sq_admin_insert" ON public.session_questions
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "sq_admin_update" ON public.session_questions
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 관리자만: 문제 삭제
CREATE POLICY "sq_admin_delete" ON public.session_questions
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- =============================================================
-- submissions 정책 - ★ 최종 제출 후 수정 불가 핵심
-- =============================================================

-- 본인 제출 조회
CREATE POLICY "sub_self_select" ON public.submissions
  FOR SELECT USING (auth.uid() = user_id);

-- 관리자: 전체 제출 조회 (채점 및 현황 확인)
CREATE POLICY "sub_admin_select" ON public.submissions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 본인 제출 생성
CREATE POLICY "sub_self_insert" ON public.submissions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ★ 핵심 정책: 두 조건 모두 만족해야 수정 가능
-- 조건1: is_final = FALSE (최종 제출 전)
-- 조건2: 세션이 round_active 상태 (input 가능 시간)
CREATE POLICY "sub_self_update" ON public.submissions
  FOR UPDATE USING (
    auth.uid() = user_id
    AND is_final = FALSE
    AND EXISTS (
      SELECT 1 FROM public.game_sessions gs
      WHERE gs.id = session_id
        AND gs.status = 'round_active'
        AND gs.is_paused = FALSE
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    AND is_final = FALSE
  );

-- 관리자: is_final 강제 설정 가능 (RPC 함수 내 SECURITY DEFINER로 처리됨)
CREATE POLICY "sub_admin_update" ON public.submissions
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 관리자만: 제출 삭제
CREATE POLICY "sub_admin_delete" ON public.submissions
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- =============================================================
-- Realtime 활성화 (필요한 테이블만)
-- =============================================================
-- Supabase Dashboard > Database > Replication 에서 활성화하거나:
ALTER PUBLICATION supabase_realtime ADD TABLE public.game_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.submissions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.session_questions;
