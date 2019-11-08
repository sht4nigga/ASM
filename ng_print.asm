;			____________________________________
;			Тип процессора__КР580ВМ60А/К1811ВМ85А

; 	Директивы
; 	транслятору
; 	адресованы
PortA		EQU	80H		;Адрес порта A
PortB		EQU	81H		;Адрес порта B
PortC		EQU	82H		;Адрес порта C
PorCRL		EQU	83H		;порт управления ППИ(паралльельно последовательный интерфейс - обмен данными)

;______________________________Основная программа________________________________
		ORG	800H		;Адрес начала загрузки программы
		MVI	A,89H		;Число 89H отправляем в А_ккумулятор	(1.1)
		OUT	porCRL		;Выводим  код (89H) в порт управления из А_ккумулятора
		LXI	SP,0900H	;Стек размещаем с 900 ячейки, суём в регистр указаеля стека
		MVI	B,0		;Обнуляем значение регистра В (переменная КОЛИЧЕСТВА ЛЮДЕЙ)
Reset:		MVI	C,50		;Суём в рег.-р общ. назн. "С" число 50 (для i-- при проверке нажатия 50 раз - защ.от дребезга - 2.1)
INPUT:		IN	PortC		;Ввод данных с порта С (2.2)
		ANI	06H		;Сравниваем с маской (логическое умножение на 6 => 0000 0110)
		JZ	Reset		;Если получаем 0 при логическом умножени, то переходим в Reset (2.1)
		DCR	C		;Декрементируем регистр "С"
		JNZ	INPUT		;не равно 0, идем в (2.2)
		MOV	H,A		;Сохр. binary число(разряд кнопки - сигнал с датчика вх\вых пассажира) в рег.-е "H" из А_ккумулятора
Put:		IN	PortC		;Переход к 2.6
		CPI	0		;Сравниваем с "0" через вычитание
		JNZ	Put		;___Конец 2___		
		MOV	A,H		;Суём число из регистра "Н" в А_ккумулятор    ___Начало 3___
		CPI	2		;Сравнение с разрядом(для кнопки 1) 0000 0010 - число "2" соответствует кнопке № 1
		JNZ	E1		;Перешли к 3.1.1
		MOV	A,B		;Пересылка из регистра памяти В в А_ккумулятор
		ADI	1		;Инкрементируем значение А_ккумулятора
		DAA			;Десятичная коррекция А_ккумулятора
		JMP	E4		;Переход к Е4
E1:		CPi	4		;Сравнение А_ккумулятора с числом 0000 0100(3 разряд = 1), соответствующим кнопке(датчику 2)
		JNZ	Reset		;Если на Reset перескакиваем, отладчик даст другой адрес, соответствующий ___Началу 2___
		MOV	A,B		;Пересылаем из регистра памяти "В" в А_ккумулятор
		SUI	1		;Вычитаем из А_ккумулятора единицу(0000 0001) пункт 3.1.2
		MOV	D,A		
;______________________________Начало десятичной коррекции для декримента__________________________________________
		ANI	15		;Обнуляем старшую тетраду маски(путем логического умножения)
		CPI	15		;Сравниваем младшую тетраду с числом 15 (0000 1111)
		JNZ	E3		;В случае, если сравнение с младшей единичной тетрадой не равно 0, то переходим к Е3
		JZ	corr		;В случае, если равно 0, то 5.1.1 (corr)
corr:		MOV	A,D		;Из регистра D сохраняем значение в А_ккумулятор
		SUI	6		;Вычитаем из А_ккумулятора число 6 (0000 0110) - десятичная коррекция единичной тетрады
		JMP	E4		;Сохраняем число пассажиров
E3:		MOV	A,D		;Суём в А_ккумулятор число из регистра "D"
E4:		MOV	B,A		;Количество пассажиров после вычитания сохраняем в регистре "В"
;_____________________________Конец программы десятичной коррекции для декремента____________________________

		MOV	A,B		;Пересыл из регистра В в А_ккумулятор
		ANI	0F0H		; 4.1 - Наложение маски на младшую тетраду
		RRC			; 4.2 - Сдвиг старшей тетрады вправо
		RRC
		RRC
		RRC
		CALL	TABCN		;Вызов подпрограммы преобразования в 7-й код
		OUT	PortA		; 4.4 - вывод в порт А
		MOV	A,B		; 4.5 - Наложение маски(логическое умножение) на старшую тетраду
		ANI	0FH		;Обнуление А_ккумулятора - старшей тетрады
		CALL	TABCN		;4.6 - преобразование в 7-й код
		OUT	PortB		;4.7 - вывод данных из (D&E)а в порт "В"
		JMP	Reset		;Зацикливаем алгоритм - типа он прыгает в Reset(самое начало программы, где "MVI С,50")
TABCN:		LXI	H,Base		;Установка базового адреса таблицы |||то число, относительно которого эта ДИЧЬ считает=находит
					;символ цифры для семисегментного индикатора в таблице соответствия|||
		MOV	E,A		;Число из А_ккумулятора суём в регистр памяти "E" - формируем индекс числа в таблице для 7-ого инд.
		MVI	D,0		;Чистим регистр "D", т.к. предыдущее значение в нём уже не требуется
		DAD	D		;Суммируем пару регистров D(D&E) с парой регистров H(H&L)
		MOV	A,M		;Суём в А_ккумулятор 7-й код из таблицы, которую пнули в память
		RET			;Возврат из подпрограммы таблицы чисел, соотв.7-ому индикатору.


Base:		DB	0FCH		; Число "0"
		DB	60H		; Число "1"
		DB	0DAH		; Число "2"
		DB	0F2H		; Число "3"
		DB	66H		; Число "4"
		DB	0B6H		; Число "5"
		DB	0BEH		; Число "6"
		DB	0E0H		; Число "7"
		DB	0FEH		; Число "8"
		DB	0F6H		; Число "9"
		END
