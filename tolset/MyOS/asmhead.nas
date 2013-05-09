; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpack�̃��[�h��
DSKCAC	EQU		0x00100000		; �f�B�X�N�L���b�V���̏ꏊ
DSKCAC0	EQU		0x00008000		; �f�B�X�N�L���b�V���̏ꏊ�i���A�����[�h�j

; BOOT_INFO�֌W
CYLS	EQU		0x0ff0			; �u�[�g�Z�N�^���ݒ肷��
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; �F���Ɋւ�����B���r�b�g�J���[���H
SCRNX	EQU		0x0ff4			; �𑜓x��X
SCRNY	EQU		0x0ff6			; �𑜓x��Y
VRAM	EQU		0x0ff8			; �O���t�B�b�N�o�b�t�@�̊J�n�Ԓn

		ORG		0xc200			; ���̃v���O�������ǂ��ɓǂݍ��܂��̂�

; ��ʃ��[�h��ݒ�

		MOV		AL,0x13			; VGA�O���t�B�b�N�X�A320x200x8bit�J���[
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; ��ʃ��[�h����������iC���ꂪ�Q�Ƃ���j
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; �L�[�{�[�h��LED��Ԃ�BIOS�ɋ����Ă��炤

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; PIC�ر�һ���ж�
;	����AT���ݻ��Ĺ�����Ҫ��ʼ��PIC
;	������CLI֮ǰ���У�������ʱ�����
;	������PIC��ʼ��

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; ���Ҫ����ִ��OUTָ���Щ���ֻ��޷���������
		OUT		0xa1,AL

		CLI						; ��ֹCPU������ж�

; Ϊ����CPU����1M���ϵ��ڴ�ռ�

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20 ���ź�����ʹ�ڴ��1MB���ϵĲ��ֱ�̿�ʹ��״̬
		OUT		0x60,AL
		CALL	waitkbdout

; �л�������ģʽ

[INSTRSET "i486p"]				; ��Ҫʹ��486ָ�������

		LGDT	[GDTR0]			; �趨��ʱGDT
		MOV		EAX,CR0			; CR0:control register 0 ֻ�в���ϵͳ�ܲ����ļĴ���������Ҫ
		AND		EAX,0x7fffffff	; ��bit31Ϊ0��Ϊ�˽��ư䣩
		OR		EAX,0x00000001	; ��bit0Ϊ1��Ϊ���л�������ģʽ��
		MOV		CR0,EAX
		JMP		pipelineflush   ; pipeline�ܵ�
pipelineflush:
		MOV		AX,1*8			;  �ɶ�д�Ķ�32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack�Ĵ���

		MOV		ESI,bootpack	; ����Դ
		MOV		EDI,BOTPAK		; ����Ŀ�ĵ�
		MOV		ECX,512*1024/4
		CALL	memcpy

; �����������մ��͵���������λ��ȥ

; ���ȴ�����������ʼ

		MOV		ESI,0x7c00		; ����Դ
		MOV		EDI,DSKCAC		; ����Ŀ�ĵ�
		MOV		ECX,512/4
		CALL	memcpy

; ����ʣ�µ�

		MOV		ESI,DSKCAC0+512	; ����Դ
		MOV		EDI,DSKCAC+512	; ����Ŀ�ĵ�
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; ���������任Ϊ�ֽ���/4
		SUB		ECX,512/4		; ��ȥIPL
		CALL	memcpy

; ������asmhead��ɵĹ���������ȫ�����
;	�Ժ�ͽ���bootpack�����

; bootpack������

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; û��Ҫ���͵Ķ���ʱ��JZ: jump if zero
		MOV		ESI,[EBX+20]	; ת��Դ
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; ת��Ŀ�ĵ�
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; ջ��ʼֵ
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02		
		JNZ		waitkbdout		; AND�Ľ���������0��������waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; ��������Ľ���������0������ת��memcpy
		RET


		ALIGNB	16
GDT0:
		RESB	8				; NULL selector
		DW		0xffff,0x0000,0x9200,0x00cf	; ���Զ�д�Ķ�(segment)32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; ����ִ�еĶ�(segment)32bit (bootpack��)
		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
