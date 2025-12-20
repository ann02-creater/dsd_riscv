# Vivado 시뮬레이션 및 DarkRISCV 아키텍처 분석 보고서

이 문서는 Xilinx Nexys A7 100T FPGA 보드 환경에서 동작하는 수정된 DarkRISCV 코어의 신호 분석, 하드웨어 구성, 그리고 원본 버전과의 차이점을 상세히 기술합니다.

---

## 1. Vivado 시뮬레이션 포트별 설명 (Signal Description)

Vivado 시뮬레이션 파형에서 볼 수 있는 `darksocv` 모듈의 주요 신호들에 대한 설명입니다.

### 최상위 물리 포트 (FPGA 핀과 직접 연결)
*   **`XCLK` (External Clock)**: 보드 외부에서 입력되는 100MHz 메인 클럭 소스입니다.
*   **`XRES` (External Reset)**: 보드 리셋 버튼 신호입니다. Nexys A7은 **Active Low** (0일 때 리셋)를 사용합니다.
*   **`UART_RXD / TXD`**: PC와 통신하기 위한 USB-UART 시리얼 수신/송신 라인입니다.
*   **`LED`**: 보드상의 16개 LED 출력입니다. 디버깅 상태나 게임 결과를 표시합니다.
*   **`SW`**: 보드상의 16개 슬라이드 스위치 입력입니다. 게임 입력값 설정 등에 사용됩니다.
*   **`SEG / AN`**: **7-Segment Display** 제어 신호입니다.
    *   `SEG[7:0]`: 숫자 및 문자를 표현하는 세그먼트(a-g, dp) 신호.
    *   `AN[7:0]`: 8개의 자리(Digit) 중 어느 곳을 켤지 선택하는 Anode 신호.

### 내부 버스 및 시스템 신호 (SoC 내부 동작)
*   **`CLK / RES`**: 내부 로직에서 실제로 사용하는 시스템 클럭과 리셋 신호입니다.
*   **`iport / oport`**:
    *   `iport`: 스위치(`SW`) 값이 연결되어 CPU가 값을 읽을 수 있는 입력 포트.
    *   `oport`: CPU가 값을 기록하면 LED나 7-Segment로 전달되는 출력 포트.
*   **`led_32`**: 내부 32비트 레지스터 신호로, 하위 16비트만 물리적 LED에 연결됩니다.
*   **`XIRQ` (Interrupt Request)**: 주변장치(UART, 타이머 등)가 CPU에 보내는 인터럽트 요청 신호입니다.

### DarkRISCV 코어 버스 신호 (메모리/IO 접근용)
CPU(`darkriscv`)가 메모리나 IO(`darkio`)와 데이터를 주고받을 때 사용되는 핵심 신호들입니다.
*   **`XDREQ` (Data Request)**: 데이터 메모리 접근 요청 신호.
*   **`XADDR` (Address)**: 접근하려는 32비트 메모리 주소 (예: `0x80000004`).
*   **`XATAO` (Data Output)**: CPU가 기록하려는 데이터 값.
*   **`XWR / XRD`**: 쓰기(`1`) / 읽기(`1`) 제어 신호.
*   **`XDREQMUX`**: 주소(`XADDR`) 상위 비트에 따라 어떤 장치(ROM, RAM, IO 등)를 선택할지 결정하는 신호.
*   **`XATAIMUX`**: 선택된 장치로부터 읽어온 데이터.
*   **`XDACKMUX`**: 선택된 장치의 응답(Acknowledge) 신호.
*   **`HLT` (Halt)**: 메모리 응답을 기다리며 파이프라인이 정지된 상태.

### 명령어 인출 (Instruction Fetch) 관련
*   **`IDREQ`**: 명령어 인출 요청.
*   **`IADDR`**: 가져올 명령어의 주소 (PC).
*   **`IDATA`**: 메모리에서 인출된 32비트 명령어 코드.
*   **`IDACK`**: 명령어가 준비되었음을 알리는 신호.

---

## 2. FPGA 보드 상에서의 버스 크기 및 클럭 사양

### 1) 버스의 크기 (Bus Width)
*   **내부 데이터/주소 버스**: 32-bit RISC-V 아키텍처이므로 **32-bit (4바이트)**가 기본입니다. (`XADDR`, `XATAO`, `IDATA` 등)
*   **물리적 IO 버스 (Nexys A7)**:
    *   LED: **16-bit** (`LED[15:0]`)
    *   Switch: **16-bit** (`SW[15:0]`)
    *   7-Segment: **8-bit** (`SEG`) + **8-bit** (`AN`)
    *   UART: **1-bit** 직렬 통신 (`RX`, `TX`)

### 2) 클럭 속도
*   **시스템 클럭 (`CLK`)**: **100 MHz** (Nexys A7 온보드 오실레이터 속도).
*   **CPU 동작 속도**: **100 MHz** (1 Cycle = 10ns).
*   **UART**: 100MHz 시스템 클럭을 분주하여 설정된 Baud Rate(예: 115200bps)로 동작.
*   **7-Segment Refresh**: `darkseg.v` 내부에서 100MHz를 $2^{17}$로 분주하여 약 **762 Hz**로 동작 (사람 눈에 깜빡임이 보이지 않음).

---

## 3. DataPath와 Controller 구성 (3-Stage Pipeline)

DarkRISCV는 Fetch, Decode, Execute의 **3단 파이프라인** 구조를 가집니다.

*   **Controller (제어 유닛)**: `darkriscv.v` 내부의 Decoder 로직이 담당합니다.
    *   명령어(`IDATA`)의 Opcode를 해석하여 제어 신호(`LUI`, `JAL`, `BCC` 등)를 생성합니다.
    *   `HLT` 신호를 통해 메모리 대기 상태를 제어하고, 분기 발생 시 `FLUSH` 신호로 파이프라인을 비웁니다.
*   **DataPath (데이터 경로)**:
    *   **Register File**: `REGS[0:31]` (32비트 레지스터 32개).
    *   **ALU**: `RMDATA` 와이어상에서 산술/논리 연산을 수행합니다.
    *   **PC Logic**: `NXPC` 로직을 통해 다음 실행 주소(+4 또는 점프)를 계산합니다.

---

## 4. 게임 로직에 따른 IP 변경 사항

게임(홀짝 맞추기) 구현을 위해 불필요한 IP를 제거하고 필요한 기능만 최적화하였습니다.

*   **입력 (Input)**:
    *   **[변경 전]:** 복잡한 PS/2 키보드 컨트롤러 사용.
    *   **[변경 후]:** **UART (PC 키보드)** + **On-board Switch**로 단순화하여 신뢰성 확보.
    *   `darkio.v`에서 주소 디코딩을 통해 스위치 값을 읽도록 변경.
*   **출력 (Output)**:
    *   **[변경 전]:** VGA 모니터 출력 컨트롤러.
    *   **[변경 후]:** **7-Segment Display** + **LED** + **UART Text** 출력.
    *   `darkseg.v` 모듈을 신규 개발 및 추가하여 숫자를 직관적으로 표시.

---

## 5. 디코딩 (Decoding) 구조

디코딩은 크게 두 단계로 이루어집니다.

1.  **버스 주소 디코딩 (`darksocv.v`)**:
    *   `XADDR[31:30]` 상위 비트를 검사하여 접속할 하드웨어 모듈을 선택합니다.
    *   `00`: Instruction Memory (ROM)
    *   `01`: Data Memory (RAM)
    *   `10`: IO Peripheral (DarkIO)
2.  **명령어 디코딩 (`darkriscv.v`)**:
    *   `IDATA[6:0]` (Opcode): 명령어 종류 판별 (Load, Store, Branch 등).
    *   `IDATA[14:12]` (Funct3), `IDATA[31:25]` (Funct7): 세부 연산 종류 판별 (ADD, SUB, XOR 등).

---

## 6. 기존 원본(Legacy) vs 현재 수정본(Modified) 차이점 비교

| 구분 | 기존 원본 (DarkRISCV Standard / 이전 프로젝트) | 현재 수정본 (Nexys A7 Porting for Game) |
| :--- | :--- | :--- |
| **파이프라인** | 3-Stage (설정 가능) | **3-Stage Pipeline** (검증 완료) |
| **타겟 보드** | 범용 (다양한 보드 지원) | **Xilinx Nexys A7-100T 전용 최적화** |
| **클럭 / 리셋** | 보드별 상이 (보통 Reset High) | **100MHz**, **Active Low Reset** (CPU 내부 로직 수정됨) |
| **입력 장치** | PS/2, 마우스 등 복잡한 주변기기 | **UART Terminal, Dip Switch** (단순화 및 안정성 강화) |
| **출력 장치** | VGA 그래픽/텍스트 콘솔 | **7-Segment Display** (신규), LED, UART Echo |
| **IO 매핑** | 커스텀 IO 맵 사용 | **DarkIO 표준 맵 준수** + 7-Segment 추가 매핑 |
| **주요 IP** | `vga_text_display`, `ps2_kbd` | **`darkseg` (신규 개발)**, `darkuart` (기존 활용) |
| **소프트웨어** | 부트스트랩 코드 부재로 실행 불가 | **Startup Code (`boot.S`)** 추가, **Linker Script** 완비, **.coe** 생성 자동화 |

**핵심 요약:**
현재 버전은 Nexys A7 보드에서 **"홀짝 게임"**을 안정적으로 구동하기 위해 하드웨어를 경량화하고 입출력 인터페이스를 최적화한 버전입니다. 특히 **소프트웨어(C코드)가 하드웨어 위에서 정상적으로 부팅하고 실행될 수 있도록 링커 스크립트와 스타트업 코드를 완비**했다는 점에서 기존 버전의 실행 불가 문제를 해결한 완성본이라 할 수 있습니다.
