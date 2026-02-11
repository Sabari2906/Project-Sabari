# Specification

## Summary
**Goal:** Build a clinical training and MCQ assessment platform with role-based access, admin-approved PDF training content, objective exam scoring, certificates, audit logs, and a consistent professional visual theme.

**Planned changes:**
- Implement Internet Identity sign-in with persisted roles (Therapist, Doctor, Clinical Trainer/Admin) and enforce authorization on all protected UI/actions.
- Add admin workflow to upload PDF training materials, organize into courses/modules, and manage status lifecycle (Draft, In Review, Published, Archived).
- Build learner training experience: published course catalog, course detail/module list, in-app PDF viewer, and per-user module progress tracking.
- Implement MCQ-only exam management (admin) and exam attempts with backend objective auto-scoring (learner), including storing attempt answers/timestamps/score/pass-fail.
- Issue and store immutable certificates on passing attempts; provide learner certificate list/detail with printable/downloadable view; add admin certificate lookup.
- Record append-only audit logs for key learner/admin actions and provide an admin-only audit log viewer with filtering.
- Add UX guardrails/disclaimers (training-only, no medical advice) and ensure no features generate medical recommendations or AI-authored content.
- Organize the project into clear frontend/backend modules with typed frontend API bindings and React Query for all queries/mutations; add a concise architecture doc.
- Apply a consistent medical/professional UI theme (avoid blue/purple as primary colors) and render/use generated static assets for the app logo and certificate background.

**User-visible outcome:** Users can sign in with Internet Identity and, based on their role, either manage/approve/publish PDF courses and MCQ exams (Admin) or browse published training, view PDFs, take auto-scored MCQ exams, and receive printable certificates (Therapist/Doctor), with all significant actions audit-logged.
