# Agents Overview — InstantPlay

Документ описывает "агентов" (компоненты), отвечающих за управление воспроизведением аудио, обработку пользовательских взаимодействий и логику работы приложения.

---

## 🎚️ ChannelAudioController

**Роль:** Управляет воспроизведением одного аудиофайла (канала), включая fade-in/fade-out, позиционирование, загрузку и паузу.

**Методы:**

* `toggle()` — основная логика включения/остановки воспроизведения.
* `loadSource()` — загружает источник из файла.
* `fadeIn/fadeOut()` — управление громкостью со временем.
* `cancelFadeTimers()` — сбрасывает все таймеры.
* `dispose()` — освобождает ресурсы.

**Состояния:**

* `isPlaying` — играет ли в данный момент.
* `isCompleted` — завершено ли воспроизведение.
* `isFading` — выполняется ли сейчас плавное изменение громкости.

---

## 🔘 Knob Button Agent

**Роль:** Представляет собой пользовательский интерфейс для запуска/остановки аудио. Делегирует действия `ChannelAudioController`.

**Поведение:**

* При нажатии:

  * Если аудио **не играет** — запускает через `controller.toggle()`.
  * Если **играет** — останавливает (в зависимости от fade-out).
* Игнорирует множественные нажатия, если уже выполняется команда.

---

## 🎧 AudioPlayer (JustAudio)

**Библиотека:** `just_audio`

**Роль:** Физический проигрыватель аудиофайлов. Необходимая обёртка в `ChannelAudioController`.

**Особенности:**

* Управление источником.
* Потоковое состояние (`playerStateStream`).
* Громкость (`setVolume()`).
* Методы: `play()`, `pause()`, `seek()`, `stop()`, `setAudioSource()`.

---

## ⚙️ ChannelStripModel

**Роль:** Хранит параметры канала:

* `filePath`
* `startTime`
* `stopTime`
* `fadeInSeconds`
* `fadeOutSeconds`
* `name`

---

## 📝 Логика Воспроизведения

1. Нажатие на кнопку:

   * Если **не играет**:

     * Загружается источник (если нужно)
     * Выполняется `fade-in` (если задан)
     * Старт воспроизведения
   * Если **играет**:

     * Выполняется `fade-out` (если задан)
     * Затем стоп и сброс на `startTime`

---

# 📌 Примечания

* Один `ChannelAudioController` управляет одним аудиофайлом.
* UI-кнопка "knob" просто передаёт команды контроллеру.
* Fade-in/out реализован вручную через `Timer.periodic`.
