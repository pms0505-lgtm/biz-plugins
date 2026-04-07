---
name: ax-eval-onboard
description: "AX-Eval 초기 설정. 역할 선택, 프로젝트 매핑, 첫 로그 변환까지 안내."
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---

# ax-eval-onboard: 초기 설정

사업관리본부 AX 레벨 평가 시스템을 처음 설치할 때 딱 한 번 실행합니다.

---

## 실행 순서

### 1단계: 환영 메시지

다음 메시지를 출력합니다:

```
안녕하세요! AX-Eval입니다.

이 시스템은 여러분의 Claude Code 활용 수준을 분석하여
성장을 추적하고 맞춤 팁을 드립니다.

설정은 딱 2분이면 끝납니다. 시작할게요!
```

---

### 2단계: 작업 디렉토리 생성

다음 디렉토리를 생성합니다:

```bash
mkdir -p ~/ax-eval/config
mkdir -p ~/ax-eval/conversations
mkdir -p ~/ax-eval/assessments
mkdir -p ~/ax-eval/exports
mkdir -p ~/ax-eval/growth-log/weekly
```

---

### 3단계: 역할 선택

**1단계:** AskUserQuestion으로 직군 계열을 묻습니다 (4개 옵션):

```
어떤 직군에 해당하시나요? (AX 레벨 평가 가중치 조정에 사용됩니다)

1. 마케터 — UA마케터 또는 CRM마케터
2. 디자이너 — 브랜드/UI 디자인, 크리에이티브 작업
3. 데이터분석가 — 데이터 정리, 지표 분석, 리포트
4. 개발자 — 기능 개발, 코드 리뷰, 자동화 스크립트
```

**2단계 (마케터 선택 시에만):** AskUserQuestion으로 세부 직군을 묻습니다:

```
마케터 세부 직군을 선택해주세요:

1. UA마케터 — 광고 집행, 캠페인 기획, 소재 제작
2. CRM마케터 — 고객 세그먼트, 리텐션 메시지, 자동화
```

디자이너/데이터분석가/개발자 선택 시 2단계 건너뜀.

선택 후 `~/ax-eval/config/profile.json`에 저장:

```json
{
  "role": "UA마케터",
  "role_key": "ua-marketer",
  "created_at": "YYYY-MM-DD",
  "name": ""
}
```

role_key 매핑:
- UA마케터 → `ua-marketer`
- CRM마케터 → `crm-marketer`
- 디자이너 → `designer`
- 데이터분석가 → `data-analyst`
- 개발자 → `developer`

---

### 4단계: Claude Code 프로젝트 자동 발견

`~/.claude/projects/` 디렉토리를 스캔하여 프로젝트 목록을 확인합니다.

```bash
ls ~/.claude/projects/
```

발견된 프로젝트 디렉토리 이름을 사람이 읽기 좋은 이름으로 매핑합니다.

`~/ax-eval/config/project_names.json`에 저장:

```json
{
  "-Users-username-projectname": "프로젝트명"
}
```

프로젝트가 많으면 (5개 이상) 가장 최근에 수정된 상위 5개만 먼저 처리합니다.

---

### 5단계: 첫 로그 변환

플러그인의 `scripts/convert_sessions.py`를 실행합니다:

```bash
python3 {PLUGIN_SCRIPTS_DIR}/convert_sessions.py \
  --output-dir ~/ax-eval/conversations \
  --names-file ~/ax-eval/config/project_names.json
```

변환 결과를 출력합니다.

---

### 6단계: 완료 메시지

```
✅ 설정 완료!

이제 두 가지 명령어를 기억하세요:

📊 /ax-eval 체크  — 내 AX 레벨 확인 (주 1회 권장)
💡 /ax-eval 팁    — 현재 수준에 맞는 활용법

첫 체크를 해볼까요? /ax-eval 체크 를 입력해보세요!
```

---

## 오류 처리

- Python 없음: "Python 3.8 이상이 필요합니다. IT 담당자에게 문의하세요."
- `~/.claude/projects/` 없음: "Claude Code 대화 기록이 없습니다. Claude Code를 사용해보신 후 다시 실행해주세요."
- 이미 설정됨 (`~/ax-eval/config/profile.json` 존재): "이미 설정되어 있습니다. `/ax-eval 체크` 또는 `/ax-eval 팁`을 사용하세요."
