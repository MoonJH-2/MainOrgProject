납부서비스
홈 오픈API 오픈지로 납부서비스
1. 제휴사 연동 납부
제휴사의 서비스를 이용하여 고객이 지로 요금을 납부하기 위한 서비스입니다. 지로 요금의 납부 방법은 조회 납부와 입력 납부로 구분됩니다. ‘조회 납부’는 납부할 장표에 인자된 전자납부번호로 고지 내역을 조회하여 납부 하는 방식을 의미합니다. ‘입력 납부’는 고지 내역 조회 절차 없이 장표에 인자된 정보를 직접 입력하여 납부하는 방식을 의미합니다. 오픈지로는 납부를 위해 고객으로부터 계좌 비밀번호를 입력받는 모바일 웹페이지를 제공합니다. 제휴사는 해당 페이지의 URL을 생성하기 위해 오픈지로 시스템이 제공하는 오픈API 를 사용합니다. URL 수신 이후는 일반 HTTP 요청/응답으로 납부를 진행합니다.
제휴사 연동 납부 안내
제휴사 연동 납부 결제 URL 생성 API는 조회납부, 입력납부 두 가지 종류가 있습니다. 두 API모두 POST 메소드로 호출되며, 상세 스펙 및 호출 예제는 아래와 같습니다.

Client ID : 0e7b73a1-fe17-431c-8134-c27bedcaaf91
Client Secret : 38185713-9d82-4874-9c2e-66e311457fb0
Callback URL :

1.1. 제휴사 연동 조회납부 결제 URL 생성
요청메시지 URL
HTTP URL	https://api.giro.or.kr/v1/payments/giro-inqr-pay-url
요청 메시지 명세
Header
HTTP Method	POST
Content-Type	application/json; charset=UTF-8
Authorization	Bearer <access_token >
 
Body
구분	파라미터	설명	필수	타입	길이
최소	최대
제휴사정보	ptco_code	제휴사 코드	Y	N	9	9
org_tran_id	제휴사 거래고유번호	Y	AN	30	30
부과정보	cls_code	고지내역 이용기관 분류코드	Y	N	2	2
giro_no	고지내역 이용기관 지로번호	Y	N	7	7
epay_no	전자납부번호 (“-”제외)	Y	AN	-	14
pay_yymm	부과 년월 (YYYYMM)	Y	N	6	6
noti_issu_type	고지 형태	Y	N	1	1
etc_type_code	기타 구분 코드	Y	N	2	2
납부자정보	pyr_name	예금주(납부자) 성명	Y	AHNS	-	10
pyr_brdd	예금주(납부자) 생년월일/사업자번호	Y	N	6	10
bank_code	출금 금융기관 코드	Y	N	3	3
acnt_no	출금 계좌 번호 (“-”를 제외한 숫자만)	Y	N	-	16
pyr_cell_no	납부자 연락처 (휴대전화번호)	Y	N	-	14
pyr_ci	납부자 CI	N	ANS	-	88
요청 메시지 형태
{
    "ptco_code" : "901012345",
    "org_tran_id" : "951012345T20201021152245C00012",
    "cls_code" : "90",
    "giro_no" : "1234567",
    "epay_no" : "6004744616",
    "pay_yymm" : "202009",
    "noti_issu_type" : "0",
    "etc_type_code" : "00",
    "pyr_name" : "김지로",
    "pyr_brdd" : "830322",
    "bank_code" : "020",
    "acnt_no" : "12345678001"
    "pyr_cell_no" : "01012345678",
    "pyr_ci" : "B9VjDzU/Eo53vZWRylYXFFREh5HIki2aJ11kt0gPf9S34+djci9VH4hPV0TxBXlSFCqVZfdcgdcrkvySRo20Dw=="
}
응답 메시지 명세
Header
Content-Type	application/json; charset=UTF-8
 
Body
파라미터	설명	타입	길이
최소	최대
rsp_code	응답코드(API)	AN	5	5
rsp_msg	응답메시지(API)	AHNS	0	300
org_tran_id	요청받은 제휴사 거래고유번호 제휴사는 요청 거래고유번호와 동일한 값 수신 여부 검증 다른 값을 수신하였다면 오류처리 필요	AN	30	30
next_redirect_url	오픈지로 모바일 웹페이지 주소 계좌비밀번호 입력을 위한 모바일 웹페이지 URL 응답코드가 정상(A0000)인 경우 제공
※ URL 유효시간 : 10분	ANS	-	256
응답 메시지 형태
{
    “rsp_code” : “A0000”,
    “rsp_msg” : “정상 처리”,
    "org_tran_id" : "951012345T20201021152245C00012",
    “next_redirect_url” : “https://www.giro.or.kr/open/apipay.do?T=bad3ca116631ec2415b99a95ecd7545d”
}
1.2. 제휴사 연동 입력납부 결제 URL 생성
요청메시지 URL
HTTP URL	https://api.giro.or.kr/v1/payments/giro-inpt-pay-url
응답 메시지 명세
Header
HTTP Method	POST
Content-Type	application/json; charset=UTF-8
Authorization	Bearer <access_token>
 
Body
구분	파라미터	설명	필수	타입	길이
최소	최대
제휴사정보	ptco_code	제휴사 코드	Y	N	9	9
org_tran_id	제휴사 거래고유번호	Y	AN	30	30
고지내역	공통	prtf_kind	장표 종류 (“O”:OCR, “Q”: 정액OCR, “M”:MICR)	Y	A	1	1
cls_code	고지내역 이용기관 분류코드	Y	N	2	2
giro_no	고지내역 이용기관 지로번호	Y	N	7	7
OCR	cust_inqr_no	고객조회번호 (“-”제외)	Y	N	-	20
pay_amt	납부금액	Y	N	-	9
정액 OCR	pay_amt	납부금액	Y	N	-	9
name	납부자 성명	Y	N	-	20
cust_inqr_no	납부자확인번호	Y	N	-	20
pay_yymm_seq	납부년월(회)차 (YYYYMM)	N	N	4	6
etc_pyr_info	기타납부자정보	N	AHNS	-	40
MICR	pay_amt	납부금액	Y	N	-	12
name	납부자 성명	Y	N	-	20
cust_inqr_no	납부자확인번호	Y	N	-	20
pay_yymm_seq	납부년월(회)차 (YYYYMM)	N	N	4	6
etc_pyr_info	기타납부자정보	N	AHNS	-	40
납부자정보	pyr_brdd	예금주(납부자) 생년월일/사업자번호	Y	N	6	10
pyr_name	예금주(납부자) 성명	Y	AHNS	-	10
bank_code	출금 금융기관 코드	Y	N	3	3
acnt_no	출금 계좌 번호 (“-”를 제외한 숫자만)	Y	N	-	16
pyr_cell_no	납부자 연락처 (휴대전화번호)	Y	N	-	14
pyr_ci	납부자 CI	N	ANS	-	88
요청 메시지 형태
{
    "ptco_code" : "901012345",
    "org_tran_id" : "951012345T20201021094500C00512",
    "prtf_kind" : "O",
    "cls_code" : "90",
    "giro_no" : "1234567",
    "cust_inqr_no" : "200307000102050",
    "pay_amt" : "26890",
    "pyr_brdd" : "830322",
    "pyr_name" : "김지로",
    "bank_code" : "020",
    "acnt_no" : "12345678001",
    "pyr_cell_no" : "01012345678",
    "pyr_ci" : "B9VjDzU/Eo53vZWRylYXFFREh5HIki2aJ11kt0gPf9S34+djci9VH4hPV0TxBXlSFCqVZfdcgdcrkvySRo20Dw=="
}
응답 메시지 명세
Header
Content-Type	application/json; charset=UTF-8
 
Body
파라미터	설명	타입	길이
최소	최대
rsp_code	응답코드(API)	AN	5	5
rsp_msg	응답메시지(API)	AHNS	0	300
org_tran_id	요청받은 제휴사 거래고유번호 제휴사는 요청 거래고유번호와 동일한 값 수신 여부 검증 다른 값을 수신하였다면 오류처리 필요	AN	30	30
next_redirect_url	오픈지로 모바일 웹페이지 주소 계좌비밀번호 입력을 위한 모바일 웹페이지 URL
※ URL 유효시간 : 10분	ANS	-	256
응답 메시지 형태
{
    “rsp_code” : “A0000”,
    “rsp_msg” : “정상 처리”,
    "org_tran_id" : "951012345T20201021152245C00012",
    “next_redirect_url” : “https://www.giro.or.kr/open/apipay.do?T=bad3ca116631ec2415b99a95ecd7545d”
}
2. 링크납부
이용기관에서 부과한 요금이 금융회사에 수납되었는지 여부를 확인합니다. 오픈지로 시스템은 일반 지로요금 납부 가능한 모든 채널(오픈지로 납부 포함)을 대상으로 실시간 수납여부를 확인하여 응답합니다.
링크납부 안내
링크납부 URL 생성 API는 POST 메소드로 호출되며, 상세 스펙 및 호출 예제는 아래와 같습니다.
2.1. 링크납부 URL 생성
요청메시지 URL
HTTP URL	https://api.giro.or.kr/v1/payments/link-pay-url
응답 메시지 명세
Header
HTTP Method	POST
Content-Type	application/json; charset=UTF-8
Authorization	Bearer <access_token>
 
Body
구분	파라미터	설명	필수	타입	길이
최소	최대
제휴사정보	ptco_code	제휴사 코드	Y	N	9	9
org_tran_id	제휴사 거래고유번호	Y	AN	30	30
고지내역	공통	cls_code	고지내역 이용기관 분류코드	Y	N	2	2
giro_no	고지내역 이용기관 지로번호	Y	N	7	7
pay_meth_type	납부 형태 구분	Y	A	1	1
조회납부	epay_no	전자납부번호 (“-”제외)	Y	AN	-	14
pay_yymm	부과 년월 (YYYYMM)	Y	N	6	6
noti_issu_type	고지 형태	Y	N	1	1
etc_type_code	기타 구분 코드	Y	N	2	2
입력납부	OCR	prtf_kind	장표 종류 (고정값 “O”)	Y	A	1	1
cust_inqr_no	고객조회번호 (“-”제외)	Y	N	-	20
정액 OCR	prtf_kind	장표 종류 (“Q”)	Y	A	1	1
cust_inqr_no	납부자확인번호	Y	N	-	20
name	납부자 성명	N	AHNS	-	20
pay_yymm_seq	납부년월(회)차 (YYYYMM)	N	N	4	6
etc_pyr_info	기타납부자정보	N	AHNS	-	40
MICR	prtf_kind	장표 종류 (고정 값 “M”)	Y	A	1	1
cust_inqr_no	납부자확인번호	Y	N	-	20
name	납부자 성명	N	AHNS	-	20
pay_yymm_seq	납부년월(회)차 (YYYYMM)	N	N	4	6
etc_pyr_info	기타납부자정보	N	AHNS	-	40
납부자정보	pyr_name	예금주(납부자) 성명	N	AHNS	-	10
pyr_brdd	예금주(납부자) 생년월일/사업자번호	N	N	6	10
bank_code	출금 금융기관 코드	N	N	3	3
acnt_no	출금 계좌 번호 (“-”를 제외한 숫자만)	N	N	-	16
pyr_ci	납부자 CI	N	ANS	-	88
요청 메시지 형태
{
    "ptco_code" : "901012345",
    "org_tran_id" : "951012345T20201021152245C00012",
    "cls_code" : "90",
    "giro_no" : "1234567",
    “pay_meth_type” : “Q”,
    "epay_no" : "6004744616",
    "pay_yymm" : "202009",
    "noti_issu_type" : "0",
    "etc_type_code" : "00"
}
응답 메시지 명세
Header
Content-Type	application/json; charset=UTF-8
 
Body
파라미터	설명	타입	길이
최소	최대
rsp_code	응답코드(API)	AN	5	5
rsp_msg	응답메시지(API)	AHNS	0	300
org_tran_id	요청받은 제휴사 거래고유번호 제휴사는 요청 거래고유번호와 동일한 값 수신 여부 검증 다른 값을 수신하였다면 오류 처리 필요	AN	30	30
link_pay_url	오픈지로 모바일 웹페이지 주소
납부를 위한 모바일 웹페이지 URL 응답코드가 정상(A0000)인 경우 제공
※ 유효기간: 30일	ANS	-	-
응답 메시지 형태
{
    “rsp_code” : “A0000”,
    “rsp_msg” : “정상 처리”,
    "org_tran_id" : "951012345T20201021152245C00012",
    “link_pay_url” : “https://www.giro.or.kr/open/linkpay.do?T=201119bad3ca116631ec2415b99a95ecd7545d”
}
3. 납부결과 조회
조회/입력 납부(링크납부 포함)된 내역을 실시간으로 조회하는 기능입니다. 조회를 요청하는 제휴사를 통해 납부된 내역만 조회가 가능합니다. 납부결과는 납부일로부터 최대 5년까지 조회 가능합니다.
납부결과 조회 안내
납부결과 조회 API는 GET 메소드로 호출되며, 상세 스펙 및 호출 예제는 아래와 같습니다.
요청메시지 URL
HTTP URL	https://api.giro.or.kr/v1/payments
응답 메시지 명세
Header
HTTP Method	GET
Content-Type	application/json; charset=UTF-8
Authorization	Bearer <access_token>
 
Body
파라미터	설명	필수	타입	길이
최소	최대
ptco_code	제휴사 코드	Y	N	9	9
org_tran_id	제휴사 거래고유번호	Y	AN	30	30
요청 메시지 형태
{
    "ptco_code" : "901012345",
    “org_tran_id” : "951012345T20201021152245C00012"
}
응답 메시지 명세
Header
Content-Type	application/json; charset=UTF-8
 
Body
파라미터	설명	타입	길이
최소	최대
rsp_code	응답코드(API)	AN	5	5
rsp_msg	응답메시지(API)	AHNS	0	300
bill_info	고지내역	object
-	cls_code	고지내역 이용기관 분류코드	N	2	2
giro_no	고지내역 이용기관 지로번호	N	7	7
prtf_kind	장표 종류 (“O”:OCR, “Q”: 정액OCR, “M”:MICR)	A	1	1
pay_meth_type	납부 형태 구분	A	1	1
epay_no	전자납부번호	AN	-	14
pay_yymm_seq	부과년월 (YYYYMMDD)	N	-	6
noti_issu_type	고지 형태	N	-	1
etc_type_code	기타 구분 코드	N	-	2
dudt_tm1s	납기 일자(1차) (YYYYMMDD)	N	8	8
dudt_in_amt	납기내 금액	N	-	12
dudt_tm2s	납기 일자(2차) (YYYYMMDD)	N	8	8
dudt_aft_amt	납기후 금액	N	-	12
cust_inqr_no	고객조회번호 (OCR), 납부자확인번호(정액OCR, MICR)	AN	-	20
etc_pyr_info	기타납부자정보 (정액OCR, MICR)	AHNS	-	40
name	납부자 성명	AHNS	-	30
org_name	청구기관명	AHNS	-	34
deflt_strt_mm	체납 시작 월 (YYYYMM)	N	-	6
deflt_end_mm	체납 종료 월 (YYYYMM)	N	-	6
deflt_mm_cnt	체납 개월 수	N	-	3
etc_info_ttl	기타고지정보 제목	N	-	10
etc_info_cnte	기타고지정보 내용	N	-	30
pay_info	납부 정보	object
-	pay_dtm	납부 일시 (yyyyMMddHHmmss)	N	14	14
pay_amt	납부 금액	N	-	12
pyr_brdd	예금주(납부자) 생년월일/사업자번호	N	6	10
pyr_name	예금주(납부자) 성명	AHNS	-	20
bank_name	납부 금융기관 명	AHNS	-	20
acnt_no_masking	출금 계좌 번호(마스킹처리)	N	-	16
응답 메시지 형태
{
    "rsp_code" : "A0000",
    "rsp_msg" : "정상 처리",
    "bill_info" : {
        "cls_code" : "90",
        "giro_no" : "1234567",
        "prtf_kind" : "O",
        "pay_meth_type" : "Q",
        "epay_no" : "2380017707",
        "pay_yymm_seq" : "202010",
        "noti_issu_type" : "0",
        "etc_type_code" : "00",
        "dudt_tm1s" : "20201030",
        "dudt_in_amt" : "49180",
        "dudt_tm2s" : "20201131",
        "dudt_aft_amt" : "49180",
        "cust_inqr_no" : "12380017707141231012",
        "etc_pyr_info" : "",
        "name" : "(주)테스트",
        "org_name" : "ABC텔레콤",
        "deflt_strt_mm" : "",
        "deflt_end_mm" : "",
        "deflt_mm_cnt" : ""
    },
    "pay_info" : {
        "pay_dtm" : "20201028162551",
        "pay_amt" : "49180",
        "pyr_brdd" : "880920",
        "pyr_name" : "김지로",
        "bank_name" : "우리은행",
        "acnt_no_masking" : "123456*****"
    }
}