; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpackのロード先
DSKCAC	EQU		0x00100000		; ディスクキャッシュの場所
DSKCAC0	EQU		0x00008000		; ディスクキャッシュの場所（リアルモード）

; BOOT_INFO関係
CYLS	EQU		0x0ff0			; ブートセクタが設定する
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 色数に関する情報。何ビットカラーか？
SCRNX	EQU		0x0ff4			; 解像度のX
SCRNY	EQU		0x0ff6			; 解像度のY
VRAM	EQU		0x0ff8			; グラフィックバッファの開始番地

		ORG		0xc200			; このプログラムがどこに読み込まれるのか

; 画面モードを設定

		MOV		AL,0x13			; VGAグラフィックス、320x200x8bitカラー
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 画面モードをメモする（C言語が参照する）
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; キーボードのLED状態をBIOSに教えてもらう

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; PICｹﾘｱﾕﾒｻﾇﾐﾖﾐｶﾏ
;	ｸ�ｾﾝATｼ貶ﾝｻ�ｵﾄｹ貂�｣ｬﾈ郢�ﾒｪｳ�ﾊｼｻｯPIC
;	ｱﾘﾐ�ﾔﾚCLIﾖｮﾇｰｽ�ﾐﾐ｣ｬｷ�ﾔ�ﾓﾐﾊｱｻ盪ﾒﾆ�
;	ﾋ貅�ｽ�ﾐﾐPICｳ�ﾊｼｻｯ

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; ﾈ郢�ﾒｪﾁｬﾐ�ﾖｴﾐﾐOUTﾖｸﾁ�｣ｬﾓﾐﾐｩｻ�ﾖﾖｻ睾ﾞｷｨﾕ�ｳ｣ﾔﾋﾐﾐ
		OUT		0xa1,AL

		CLI						; ｽ�ﾖｹCPUｼｶｱ�ｵﾄﾖﾐｶﾏ

; ﾎｪﾁﾋﾈﾃCPUｷﾃﾎﾊ1Mﾒﾔﾉﾏｵﾄﾄﾚｴ豼ﾕｼ�

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20 ｸﾃﾐﾅｺﾅﾏﾟﾄﾜﾊｹﾄﾚｴ豬ﾄ1MBﾒﾔﾉﾏｵﾄｲｿｷﾖｱ犁ﾌｿﾉﾊｹﾓﾃﾗｴﾌｬ
		OUT		0x60,AL
		CALL	waitkbdout

; ﾇﾐｻｻｵｽｱ｣ｻ､ﾄ｣ﾊｽ

[INSTRSET "i486p"]				; ﾏ�ﾒｪﾊｹﾓﾃ486ﾖｸﾁ�ｵﾄﾐ�ﾊ�

		LGDT	[GDTR0]			; ﾉ雜ｨﾁﾙﾊｱGDT
		MOV		EAX,CR0			; CR0:control register 0 ﾖｻﾓﾐｲﾙﾗ�ﾏｵﾍｳﾄﾜｲﾙﾗ�ｵﾄｼﾄｴ貳�｣ｬｺﾜﾖﾘﾒｪ
		AND		EAX,0x7fffffff	; ﾉ鐫it31ﾎｪ0｣ｨﾎｪﾁﾋｽ�ﾖﾆｰ茱ｩ
		OR		EAX,0x00000001	; ﾉ鐫it0ﾎｪ1｣ｨﾎｪﾁﾋﾇﾐｻｻｵｽｱ｣ｻ､ﾄ｣ﾊｽ｣ｩ
		MOV		CR0,EAX
		JMP		pipelineflush   ; pipelineｹﾜｵﾀ
pipelineflush:
		MOV		AX,1*8			;  ｿﾉｶﾁﾐｴｵﾄｶﾎ32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpackｵﾄｴｫﾋﾍ

		MOV		ESI,bootpack	; ｴｫﾋﾍﾔｴ
		MOV		EDI,BOTPAK		; ｴｫﾋﾍﾄｿｵﾄｵﾘ
		MOV		ECX,512*1024/4
		CALL	memcpy

; ｴﾅﾅﾌﾊ�ｾﾝﾗ�ﾖﾕｴｫﾋﾍｵｽﾋ�ｱｾﾀｴｵﾄﾎｻﾖﾃﾈ･

; ﾊﾗﾏﾈｴﾓﾆ�ｶｯﾉﾈﾇ�ｿｪﾊｼ

		MOV		ESI,0x7c00		; ｴｫﾋﾍﾔｴ
		MOV		EDI,DSKCAC		; ｴｫﾋﾍﾄｿｵﾄｵﾘ
		MOV		ECX,512/4
		CALL	memcpy

; ﾋ�ﾓﾐﾊ｣ﾏﾂｵﾄ

		MOV		ESI,DSKCAC0+512	; ｴｫﾋﾍﾔｴ
		MOV		EDI,DSKCAC+512	; ｴｫﾋﾍﾄｿｵﾄｵﾘ
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; ｴﾓﾖ�ﾃ賁�ｱ莉ｻﾎｪﾗﾖｽﾚﾊ�/4
		SUB		ECX,512/4		; ｼ�ﾈ･IPL
		CALL	memcpy

; ｱﾘﾐ�ﾓﾉasmheadﾍ�ｳﾉｵﾄｹ､ﾗ�｣ｬﾖﾁｴﾋﾈｫｲｿﾍ�ｱﾏ
;	ﾒﾔｺ�ｾﾍｽｻﾓﾉbootpackﾀｴﾍ�ｳﾉ

; bootpackｵﾄﾆ�ｶｯ

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; ﾃｻﾓﾐﾒｪｴｫﾋﾍｵﾄｶｫﾎ�ﾊｱ｣ｬJZ: jump if zero
		MOV		ESI,[EBX+20]	; ﾗｪﾋﾍﾔｴ
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; ﾗｪﾋﾍﾄｿｵﾄｵﾘ
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; ﾕｻｳ�ﾊｼﾖｵ
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02		
		JNZ		waitkbdout		; ANDｵﾄｽ盪�ﾈ郢�ｲｻﾊﾇ0｣ｬｾﾍﾌ�ｵｽwaitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; ｼ�ｷｨﾔﾋﾋ羞ﾄｽ盪�ﾈ郢�ｲｻﾊﾇ0｣ｬｾﾍﾌ�ﾗｪｵｽmemcpy
		RET


		ALIGNB	16
GDT0:
		RESB	8				; NULL selector
		DW		0xffff,0x0000,0x9200,0x00cf	; ｿﾉﾒﾔｶﾁﾐｴｵﾄｶﾎ(segment)32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; ｿﾉﾒﾔﾖｴﾐﾐｵﾄｶﾎ(segment)32bit (bootpackﾓﾃ)
		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
