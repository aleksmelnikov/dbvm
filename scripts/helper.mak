# Printing the Value of a Makefile Variable
# https://www.cmcrossroads.com/article/printing-value-makefile-variable

# Этот скрипт — удобный хак для отладки Makefile.
# Он позволяет узнать значение любой переменной прямо из терминала, не правя сам файл.
# Вот как работают его компоненты:
# print-% 	Это шаблонное правило. Символ % ловит любое слово, которое вы напишете после дефиса.
# :		Разделитель цели. Поскольку условий после : нет, команда выполняется сразу при вызове.
# ;		Позволяет написать команду (recipe) в ту же строку, что и цель.
# @echo 	Выводит текст в консоль, при этом сама команда echo в терминале не отображается (благодаря @).
# $*		Это специальная переменная Makefile, которая подставляет то, что попало в «маску» %.
# $($*)		Это обращение к переменной, имя которой мы получили из $*.
# 	Как это использовать:
# Допустим, у вас в Makefile есть переменная SOURCE_FILES = main.c utils.c.
# $cat Makefile
# SOURCE_FILES = main.c utils.c
# $make -f Makefile -f helper.mak print-SOURCE_FILES
# Выведет: SOURCE_FILES = main.c utils.c (удобно, чтобы видеть и имя, и значение).
# $make -f Makefile -f helper.mak printvalue-SOURCE_FILES
# Выведет просто: main.c utils.c (удобно, если нужно передать результат дальше по конвейеру в другой скрипт).

# This script is a handy hack for debugging Makefiles.
# It allows you to check the value of any variable directly from the terminal without modifying the file itself.
# Here is the breakdown of how it works:
# print-%	This is a pattern rule. The % symbol catches any word you type after the hyphen.
# :		Target separator. Since there are no prerequisites listed after the :, the command runs immediately when called.
# ;		Allows you to write the command (recipe) on the same line as the target.
# @echo		Prints text to the console; the @ ensures that the echo command itself isn't displayed in the terminal.
# $*		An automatic variable in Makefile that represents the text matched by the % stem.
# $($*)		This evaluates the variable whose name was captured by $*.
# 	How to use it:
# Let's say your Makefile has the variable SOURCE_FILES = main.c utils.c.
# $cat Makefile
# SOURCE_FILES = main.c utils.c
# $make -f Makefile -f helper.mak print-SOURCE_FILES
# Output: SOURCE_FILES = main.c utils.c (Useful for seeing both the name and the value).
# $make -f Makefile -f helper.mak printvalue-SOURCE_FILES
# Output: main.c utils.c (Clean output, useful if you need to pipe the result into another script).

print-% : ; @echo $* = $($*)

printvalue-% : ; @echo $($*)
