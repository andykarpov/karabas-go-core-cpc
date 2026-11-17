# План ядра Amstrad CPC для Karabas Go / Mini / Mini G

Цель: Amstrad CPC 464 / 664 / 6128 на платах Karabas (XC6SLX25, ISE 14.7), потом CPC 464+ / 6128+ / GX4000. Основа — форк [renaudguerin/Amstrad_MiSTer](https://github.com/renaudguerin/Amstrad_MiSTer) (тег v2026.11.07, d30be17) ядра [MiSTer-devel/Amstrad_MiSTer](https://github.com/MiSTer-devel/Amstrad_MiSTer). Файлы идут через прошивку (OSD, `FL`, `F`, burst, `img_sdc`): загрузчика и soft-CPU в ядре нет.

## Что изучено (2026-11-17)

| Репо | Что даёт |
|---|---|
| MiSTer-devel/Amstrad_MiSTer (Sorgelig, 20260603) | Классика: модели 6128 / 664 / 464, CRTC type 1 / 0, GA40010 (gyurco, по вскрытому чипу), u765 (EDSK, 2 дисковода, запись), T80pa, YM2149, CDT, MF2, Dandanator, PlayCity, мыши. 64K + 512K RAM в SDRAM, clk_sys 64 МГц |
| gyurco/Amstrad_MiST | То же для MiST (EP3C25) + SYMBiFACE II (IDE, RTC) |
| **renaudguerin/Amstrad_MiSTer** (база) | + Plus / GX4000 (ASIC: спрайты, палитра 4096, split, растровые прерывания, DMA-звук, CPR), CRTC type 0 / 1 переписаны отдельными движками по CRTC Compendium (Longshot, CC BY-NC-ND: строки кредитов в исходниках CRTC и видимые кредиты сохраняем, `upstream/CREDITS.md`) |
| shaeon/aleste520ex | Алесте 520EX (GPL-3): отдельное ядро, не база |

Модели в форке: `Model` 6128 / 664 / 464 (банк `boot.rom`, `ram64k`) и `Plus model` Off / GX4000 / 6128+ / 464+ (`plus_model_select.v`: RAM 64K / 128K, FDC, лента). Plus грузится с картриджа `.CPR` пользователя; `boot.rom` (160K) — классические ROM: OS6128 + BASIC 1.1 + AMSDOS + MF2, OS664 + BASIC664 + AMSDOS + MF2, OS464 + BASIC464.

## Решения

- 2026-11-17 (пользователь): база — форк renaudguerin; ROM зашиваем в `.kg`; сначала замеры и классика, Plus потом.
- 2026-11-17 (Ф1): вся память в SRAM платы (4 МБ, 10 нс, есть на всех трёх платах), не в SDRAM: `cpc_sram` с портами `sdram.v` форка (те же слоты по 8 тактов, тот же арбитраж и задержки), банки моделей свёрнуты в 4 МБ (карта в шапке `cpc_sram.v`; ROM расширений 0..31 на модель, лента до 1 МБ). ROM (`boot.rom` 160K) — секция `roms` в `.kg`, грузится прошивкой при старте ядра.
- SV и SV-подобные `.v` идут через `sv2v` (`src/tools/sv2v.sh`), VHDL (T80, tzxplayer, Dandanator, Z80 CTC PlayCity) — в XST как есть. Правки помечены `// karabas:` / `-- karabas:`.

## Ф0. Импорт и замер (ветка f0-import)

Импорт форка в `src/rtl/amstrad/` (без Quartus PLL / .qip), справка в `upstream/`. Замер: весь `emu` из `Amstrad.sv` на заглушках MiSTer (`src/measure/stubs.sv`: выходы `hps_io` из сдвигового регистра от `HPS_BUS[0]`, чтобы XST не считал меню и загрузки константами; `video_mixer` — регистр-повторитель, свой видеотракт у нас). XC6SLX25-2, `-iobuf NO`, `make measure-xst` около 20 мин.

Правки для sv2v / XST: порт `DO` T80pa → `DOUT` (`do` — ключевое слово SV); локальные `reg x = 0` вынесены из `always` (sv2v инициализирует их на каждом такте); `mf2_store_addr` → `reg`; выход Dandanator `CHG_Rxd` не привязан к 1; u765 `i_current_track_sectors[2][2]` → `[4]` с индексом `{drive, head}` (XST делал из записи в 2-D массив тристабы, Xst:2037).

| Сборка | LUT | FF | RAMB16 | DSP48 | XST, МГц |
|---|---|---|---|---|---|
| MiSTer master 6c2c39b (классика, справка) | 9 712 (64 %) | 4 447 | 7 | 4 | 50,3 |
| Форк целиком (классика + Plus) | 25 077 (166 %) | 11 382 | 7 | 7 | 41,7 |
| **Форк, `KG_CLASSIC`** (Plus model = Off, без CPR, SSM, сохранения SNA) | **10 170 (67 %)** | 4 340 | 7 | 4 | 41,9 |

Разбивка форка целиком (`-keep_hierarchy Yes`, LUT из netlist): `asic_sprites` 7939, `asic_regs` 2566, T80 1983, CRTC 1237 (type0 332, type1 304), PlayCity 1043, u765 910, tzxplayer 749, `asic_dma` 741, GA40010 737, `asic_video` 669, сохранение SNA 660 + 474, парсеры SNA / CPR Plus 580 + 564 + 301, YM2149 492, `asic_ga_timing` 463, crt_filter 447, SSM 313, HID 269.

Выводы:
- Классика влезает: 67 % без обвязки платы (HDMI, OSD, `kg_mcu`; в других ядрах ~15–20 %) → около 85 %. PlayCity (1043) можно сделать опцией.
- Худший путь XST: запись регистра CPU → CRTC → движок type 0 → `vsync_allow`, 19 уровней, 23,9 нс при clk_sys 64 МГц (15,6 нс). CPU работает по clock enable (4 МГц), путь вероятно многотактовый, но это надо доказать ограничением или снизить clk_sys до 32 МГц — решаем в Ф1 по PAR.
- Plus в нынешнем виде не влезет: спрайты обрабатываются параллельно для всех 16 (компараторы / счётчики / сдвиги на каждый + 256 бит флагов строк). Для LX25 — переделка движка спрайтов на последовательный (время-мультиплекс) и регистров ASIC в BRAM: отдельная фаза.

## Ф1. Классика на Mini G

Обёртка `cpc_emu` (`tools/make_cpc_emu.py`: `emu` без `hps_io`, PLL, SDRAM, DDR, ADC) и `cpc_core` (сигналы `kg_mcu2` → `hps_io`), тактирование (64 или 32 МГц, см. Ф0), память в SRAM (`cpc_sram`), `boot.rom` в `.kg` → SDRAM через загрузчик (`ioctl` индекс 0), клавиатура (USB HID → матрица CPC через `hid.sv` или свой конвертер), джойстики, видео 15 кГц → удвоитель строк → 576p50 HDMI / VGA, звук. OSD: Model, CRTC, Reset. Симуляция verilator до приглашения BASIC.

## Ф2. Носители

DSK через `img_sdc` (секторный интерфейс u765 = MiST `sd_*`), CDT (F-слот в SDRAM, tzxplayer), SNA, ROM расширений, MF2, PlayCity, мыши.

Сделано (ветка f2-media, Mini G 26111716, на плате): диски A / B через файловый монтировщик `kg_mcu2` (`cpc_sd_sdc`: протокол `sd_*` MiSTer ↔ `kg_l2_img`, чтение и запись), загрузки FL Tape (.cdt), Snapshot (.sna), ROM (.ez0, .ezz, .e00–.e1f: в прошивке нет масок в расширениях) с расширением файла (`LD_EXT`). Проверено на 26111716: `cat`, `run"traxtor` с диска (26111715), `SAVE` / `CAT` / `LOAD` / `RUN` на пустом диске в A и в B, `|b` / `|a`, лента `|tape` + `run""` до меню игры (около 4 мин), снапшот, `cpc464nd.eZ0` (464 с BASIC 1.0). Мышь подключена (`ps2_mouse`), на плате не проверена. Симуляция `sim/run_disk.sh` (u765 + `cpc_sd_sdc` против модели монтировщика).

Найдено по дороге:
- XST без начального значения обрезал `image_scan_state` и `sector_search_state` u765 (весь тракт чтения): начальные значения.
- XST делал тристабы из записей в 2-D массивы u765 с индексом `[i_current_drive]` (`sector_byte_pos` и др.) и терял порядок записей: Read Data читал первый сектор и зависал в EXEC3. Найдено гейтовой симуляцией нетлиста u765 (netgen + verilator); записи переписаны с константными индексами (`for d` + `if (d == i_current_drive)`), тристабов в u765 нет.
- `IMG_OUT_LATENCY` = 3 (регистр адреса `kg_l2_img`, BRAM u765, регистр `cpc_sd_sdc`); с 2 на плате каждый сектор записывался со сдвигом на байт. `tb_disk` не ловил это из-за гонки: модель меняла адрес на том же фронте (`<=`), теперь `#1` после фронта, как регистр `kg_l2_img`: с 2 падает, с 3 проходит.
- Многотактовое ограничение в u765 (`-to u765|i_*` MiSTer) небезопасно, оставлено только от его регистров по clock enable (`TS_U765_CE_MC`).

| Сборка | LUT | Slices | Время |
|---|---|---|---|
| 26111716 Mini G | 13 413 (89 %) | 3 691 (98 %) | всё сходится |

Не сделано (решение 2026-11-18: в беклог): MF2, PlayCity.

## Ф3. Go и Mini, выпуск

Топы Go / Mini, сборка всех плат, `cores.json` karabas-go.

## Ф4. Plus / GX4000 (потом)

Переделка `asic_sprites` / `asic_regs` под LX25, CPR через `FL` / `F`, OSD `Plus model`, замер.

## Беклог

- MF2 (Multiface II): не подключён.
- PlayCity (≈1043 LUT по замеру Ф0): при 98 % slices не влезет без выкидывания чего-то другого или ужимания.
- Мышь (`ps2_mouse` подключена) на плате не проверена.
