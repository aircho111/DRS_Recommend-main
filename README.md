# DRS — AI Stock Recommendation & Drawing Stocks

NASDAQ 종목 데이터를 기반으로 두 가지 AI 서비스를 제공하는 웹 애플리케이션입니다.

- **종목 추천**: ML 모델이 예측한 Top 10 상승 종목을 3D 시각화로 표시
- **차트 검색**: 캔버스에 차트 패턴을 직접 그리면 유사한 MA20 패턴의 종목을 검색

---

## 프로젝트 구조

```
DRS_Recommend-main/
├── index.html              # 랜딩 페이지 (서비스 선택)
├── recommend.html          # 종목 추천 페이지 (Three.js 3D 포디움)
├── search.html             # 차트 검색 페이지 (스케치 기반 유사도 검색)
├── vite.config.js          # Vite 빌드 설정 (다중 진입점)
├── package.json
├── src/
│   ├── main.js             # recommend.html 스크립트 (Three.js 씬)
│   ├── search.js           # search.html 스크립트 (캔버스 드로잉)
│   └── style.css
├── public/
│   ├── favicon.svg
│   └── models/             # 3D GLTF 캐릭터 모델 (cute_alien, stick_man)
└── backend/
    ├── app.py              # 추천 API 서버 (포트 8000)
    ├── predict_service.py  # ML 예측 파이프라인 (PyCaret)
    ├── data/
    │   ├── weekly_momentum_model.pkl  # 학습된 분류 모델
    │   ├── ma20.parquet               # MA20 캐시 데이터
    │   ├── ticker_info.json           # 종목 정보
    │   └── cache_<date>.json          # 날짜별 예측 결과 캐시
    └── search_api/
        ├── main.py         # 차트 검색 API 서버 (포트 8080)
        ├── config.py       # 환경 변수 / 설정 (.env 지원)
        ├── models.py       # Pydantic 요청/응답 모델
        ├── tickers.py      # NASDAQ 티커 관리
        ├── data_io.py      # OHLC 다운로드, MA20 계산, Parquet I/O
        ├── features.py     # 벡터 정규화 파이프라인
        ├── similar.py      # DTW + Pearson 유사도 랭킹
        ├── db_io.py        # PostgreSQL / pgvector 연동 (선택)
        └── ai_analyzer.py  # Gemini AI 패턴 분석 (현재 비활성화)
```

---

## 아키텍처 개요

```
브라우저
  ├── index.html (서비스 선택)
  ├── recommend.html  ──→  http://localhost:8000/api/recommend  (backend/app.py)
  └── search.html     ──→  http://localhost:8080/similar        (backend/search_api/main.py)

백엔드
  ├── 추천 서버 (포트 8000): PyCaret ML 모델 → Top 10 종목 예측
  └── 검색 서버 (포트 8080): 스케치 벡터 → MA20 코사인/DTW 유사도 검색
      └── 데이터 소스: Parquet 캐시 (기본) 또는 PostgreSQL + pgvector (선택)
```

---

## 사전 요구사항

| 항목 | 버전 |
|------|------|
| Node.js | 18 이상 |
| Python | 3.11 이상 |
| pip 패키지 | 아래 목록 참조 |

### Python 패키지 설치

```bash
pip install fastapi uvicorn[standard] yfinance pandas numpy pycaret \
            pydantic-settings slowapi python-dotenv pyarrow
```

PostgreSQL 검색 기능을 사용하는 경우 추가:
```bash
pip install psycopg2-binary
```

---

## 서버 구동 방법

서비스를 완전히 실행하려면 **터미널 3개**가 필요합니다.

### 1. 추천 API 서버 (포트 8000)

```bash
cd backend
python app.py
```

> 서버 기동 후 http://localhost:8000/api/recommend?date=auto 로 동작 확인 가능

### 2. 차트 검색 API 서버 (포트 8080)

```bash
cd backend
python -m uvicorn search_api.main:app --host 0.0.0.0 --port 8080 --reload
```

> 서버 기동 후 http://localhost:8080/health 로 동작 확인

**최초 실행 시 데이터 수집 필요:**

```bash
curl -X POST "http://localhost:8080/ingest" \
     -H "Content-Type: application/json" \
     -d '{"days": 365}'
```

(약 1,000개 종목의 2년치 데이터를 다운로드하며 수 분 소요)

### 3. 프론트엔드 개발 서버 (포트 5173)

```bash
npm install
npm run dev
```

---

## 웹사이트 접속

| 페이지 | URL | 설명 |
|--------|-----|------|
| 랜딩 | http://localhost:5173 | 서비스 선택 화면 |
| 종목 추천 | http://localhost:5173/recommend.html | ML Top 10 3D 포디움 |
| 차트 검색 | http://localhost:5173/search.html | 스케치 유사도 검색 |

---

## API 엔드포인트 요약

### 추천 서버 (localhost:8000)

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/recommend?date=auto` | 가장 최근 금요일 기준 Top 10 추천 |
| GET | `/api/recommend?date=today` | 오늘 기준 실시간 Top 10 추천 |

### 검색 서버 (localhost:8080)

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/health` | 서버 상태 확인 |
| GET | `/stats` | 캐시된 티커 수, 데이터 소스 정보 |
| POST | `/ingest` | 주가 데이터 다운로드 및 캐싱 |
| POST | `/refresh_tickers` | NASDAQ 티커 목록 갱신 |
| POST | `/similar` | 스케치 유사 종목 검색 (Parquet) |
| POST | `/similar_db` | 스케치 유사 종목 검색 (PostgreSQL) |

---

## 환경 변수 설정 (선택)

`backend/search_api/.env` 파일을 생성하여 설정을 재정의할 수 있습니다.

```env
# 서버 설정
API_HOST=0.0.0.0
API_PORT=8080

# 데이터 소스: "parquet" (기본) 또는 "postgresql"
DATA_SOURCE=parquet

# PostgreSQL 설정 (data_source=postgresql 사용 시)
PG_HOST=localhost
PG_PORT=5433
PG_DATABASE=drs_db
PG_USER=postgres
PG_PASSWORD=your_password

# Gemini AI API 키 (AI 패턴 분석 기능, 현재 비활성화)
GEMINI_API_KEY=

# CORS 허용 오리진
CORS_ORIGINS=["*"]

# 로그 레벨
LOG_LEVEL=INFO
```

---

## 빌드 및 배포

```bash
# 프로덕션 빌드 생성
npm run build

# 빌드 결과물 미리보기
npm run preview
```

빌드 결과물은 `dist/` 디렉토리에 생성됩니다. `index.html`, `recommend.html`, `search.html` 모두 별도의 진입점으로 빌드됩니다.

---

## 주요 기술 스택

| 영역 | 기술 |
|------|------|
| 프론트엔드 번들러 | Vite 8 |
| 3D 렌더링 | Three.js + GSAP |
| 추천 ML | PyCaret (분류 모델) |
| 데이터 수집 | yfinance |
| API 서버 | FastAPI + Uvicorn |
| 유사도 검색 | 코사인 유사도 + DTW + Pearson |
| 데이터 저장 | Parquet (기본) / PostgreSQL + pgvector (선택) |
| 설정 관리 | pydantic-settings (.env 지원) |
