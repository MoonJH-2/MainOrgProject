#!/usr/bin/env python3
import sys
import os

def analyze_pdf(pdf_path):
    try:
        import PyPDF2
        
        print(f"📁 파일 경로: {pdf_path}")
        print(f"📊 파일 크기: {os.path.getsize(pdf_path):,} bytes")
        
        with open(pdf_path, 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            print(f"📄 페이지 수: {len(reader.pages)}")
            
            # 메타데이터 확인
            if reader.metadata:
                print("\n📋 메타데이터:")
                for key, value in reader.metadata.items():
                    print(f"  {key}: {value}")
            
            # 각 페이지의 텍스트 추출
            total_text = ""
            for i, page in enumerate(reader.pages):
                print(f"\n📖 페이지 {i+1}:")
                try:
                    text = page.extract_text()
                    if text and text.strip():
                        clean_text = text.strip()
                        total_text += clean_text + "\n"
                        print(f"  텍스트 길이: {len(clean_text)} 문자")
                        # 처음 200자만 미리보기
                        preview = clean_text.replace('\n', ' ')[:200]
                        print(f"  미리보기: {preview}...")
                    else:
                        print("  텍스트 없음")
                except Exception as e:
                    print(f"  오류: {e}")
            
            print(f"\n📝 전체 텍스트 길이: {len(total_text)} 문자")
            if total_text.strip():
                print("\n🔍 전체 내용:")
                print("=" * 50)
                print(total_text)
                print("=" * 50)
            
    except ImportError:
        print("PyPDF2가 설치되지 않았습니다.")
        print("설치 중...")
        os.system("pip3 install PyPDF2")
        print("설치 완료. 스크립트를 다시 실행하세요.")
        return False
    except Exception as e:
        print(f"오류 발생: {e}")
        print(f"오류 타입: {type(e).__name__}")
        return False
    
    return True

if __name__ == "__main__":
    pdf_path = "/Users/moonjh/MainOrgProject/Untitled.pdf"
    analyze_pdf(pdf_path)
