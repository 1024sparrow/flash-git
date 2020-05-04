# flash-git
> Утилита для синхронизации через флешку локальных git-репозиториев на компьютерах, не связанных сетью

Данный инструмент предназначен для
- обеспечения хранения репозитория на флешке;
- синхронизации репозиториев на разных компьютерах через флэшку путём простой вставки-и-вынимания флэшки;
- восстановления флэшки-носителя с локальной реплики репозитория на любом из компьютеров.

Это может быть применимо для следующих целей:
- Совместная работа людей на компьютерах, не соединённых сетью.
- Дублирование данных на разных компьютерах. Альтернатива использованию RAID-массивов.
- Оперативное обновление ПО у заказчика без выхода в сеть.

## Требования и текущие проблемы

На данный момент утилита работает только в Linux.

Кроме того, у данной утилиты (версия 0) имеется ряд ограничений (всвязи с багами и недоделками):
* Работать можно только в Linux. Причём созданные сейчас флешки не будут работать с будущими версиями flash-git (при обновлении потребуется переинициализация всех используемых флешек; сейчас используется файловая система ext4, которая не может использоваться в Windows, планируется переход на FAT-32 для возможности синхронизации репозиториев на компьютерах с разными операционными системами и с разной поддержкой файловых систем).
* У задействованных локальных репозиториев может быть сколько угодно "git remote", но после регистрации локального репозитория в flash-git с git в тех локальных репозиториях "git pull" и "git push" можно делать только под рутом. При обновлении flash-git права на служебные файлы git будут восстановлены.
* В списке путей к локальным директориям, если ваш локальный репозиторий находится где-то в недрах домашней директории, вместо "/home/$USER/" следует писать "~/". Автозамена таких вещей сейчас не работает, а у пользователя с другим именем при синхронизации возникнут проблемы с правами чтения-записи, так как у него домашняя директория находится по другому пути.
* Для синхронизации с флешкой после вставки надо также запустить "flash-git --device=<ФАЙЛ-УСТРОЙСТВА-ФЛЕШКИ>". Сделать синхронизацию автоматической посредством только лишь "udev rules" (Linux-specific) при вставке флешки не получилось (проблемы возникают при вызове "git push"), а через мониторящего демона пока не реализовано.
* Через одну флешку нельзя синхронизировать более 100 репозиториев.
* В синхронизируемых репозиториях нельзя создавать, удалять или переименовывать ветку "flash-git".

Процесс синхронизации репозиториев логируется в файл /usr/share/flash-git/log

## Установка

> выберите место для выкачивания данного репозитория таким образом, чтобы этот репозиторий не был впоследствии удалён, переименован или перемещён - после установки системные файлы flash-git будут ссылаться на файлы из выкачанного вами репозитория

После того, как выкачали данный репозиторий, запустите из-под root-а скрипт install.sh

Впоследствии, при желании обновить версию flash-git-а вам останется только сделать "git pull". Если же в релизе новой версии будет оговорено, что нет совместимости с предыдущими версиями, следует выполнить "./uninstall.sh" перед обновлением, и "./install.sh" после обновления, при этом все предыдущие регистрации флешек будут сброшены.

# Создание флешки-носителя (инициализация флешки)

Для того, чтобы зарегистрировать флешку как переносчик ваших локальных репозиториев, создайте текстовый файл (например, *my-repositories*) и впишите туда пути к тем репозиториям, которые хотите хранить на флешке.
```
/home/user/some_dir/00309_test_git_1
/home/user/some_dir/00309_test_git_2
```
Это должны быть проинициализированные git-репозитории. Наличие у них *origin* не имеет значения.

Вставьте флешку. Не монтируйте её. Посмотрите, в какой файл устройства отобразилась ваша флэшка (в данном случае, "sdb"):
От имени root-а запустите flash-git со следующими аргументами:
> При первой инициализации флешка будет отформатирована. Все данные на ней будут уничтожены!
```bash
$ sudo flash-git --device=/dev/sdb --alias=myFlash_00309 --repo-list=my-repositories
```
Опция --alias обязательна. Это идентификатор флешки, дополнительный к её серийному номеру. Позволяет при отображении списка зарегистрированных флешек видеть более человекочитаемый идентификатор, чем серийный номер. Рекомендуется в *alias* включать также дату инициализации флешки: это будет полезно, когда будете переинициализировать флешки (для того, чтобы вынести один локальный репозиторий на другую флешку, нужно кроме того как новую зарегистрировать, ещё и старую переинициализировать - вот тут то и полезно будет видеть дату текущей инициализации флешки)

Во время первой инициализации на флешке сохраняется список путей до репозиториев, указанных в my-repositories, а также сами локальные репозитории клонируются на флешку (не в том виде, чтоб с ними можно было напрямую прям на флешке работать).

## Инициализация флешки по локальным репозиториям:

При инициализации локальных репозиториев производится проверка на наличие в файловой системе таких директорий. Если хоть одна директория из списка синхронизируемых репозиториев уже существует, flash-git выведет сообщение о проблеме и ничего делать не будет.

Для инициализации локальных репозиториев по флешке необходимо запустить flash-git со следующими аргументами:
```bash
$ sudo flash-git --device=/dev/sdb --user=$USER --group=$USER
```
Локальные репозитории будут клонированы с флешки по путям, записанным на флешку при её инициализации.
С этими репозиториями уже можно работать.

## Синхронизация локальных репозиториев и флешки

Для синхронизации локальных репозиториев и флешки запустите flash-git с единственным аргументом:
```bash
$ sudo flash-git --device=/dev/sdb
```

## Справка и поддержка

Утилита позволяет привязать флешку, отвязать флешку, вывести список зарегистрированных флешек, а также восстановить утраченную флешку(инициализировать флешку по данным регистрации другой флешки, после чего старая флешка работать не будет, но будет работать новая).
Для того, чтобы посмотреть все опции flash-git, запустите flash-git с аргументом "--help":
```bash
$ flash-git --help
```

Copyright © 2020 Boris Vasilev. License MIT: <https://github.com/1024sparrow/flash-git/blob/master/LICENSE>
