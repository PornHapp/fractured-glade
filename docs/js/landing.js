/**
 * Fractured Glade — Landing Page JavaScript
 * ===========================================
 * Модули:
 *   1. Parallax    — глубина hero при скролле
 *   2. RiftLine    — интерактивный split Light/Dark
 *   3. ScrollReveal — появление секций при скролле
 *   4. CardTilt    — 3D наклон карточек (desktop)
 *   5. Nav         — sticky navbar + burger menu
 *
 * Все анимации — GPU-composited (transform + opacity).
 * Используется IntersectionObserver и requestAnimationFrame.
 */

(function () {
    'use strict';

    /* ==========================================================
       1. PARALLAX — глубина hero при скролле
       ==========================================================
       Каждый слой .parallax__layer имеет data-speed (0..1).
       При скролле применяется transform: translateY(scrollY * speed).
       Используется rAF для плавности.
    */
    const Parallax = {
        /** @type {HTMLElement[]} */
        layers: [],

        /** @type {number} Текущий scrollY */
        lastScroll: -1,

        /** @type {boolean} Флаг доступности (отключается при prefers-reduced-motion) */
        enabled: true,

        /**
         * Инициализация модуля параллакса.
         * Собирает все слои и проверяет prefers-reduced-motion.
         */
        init() {
            if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
                this.enabled = false;
                return;
            }

            this.layers = Array.from(document.querySelectorAll('.parallax__layer'));
            if (!this.layers.length) return;

            this._onScroll = this._onScroll.bind(this);
            window.addEventListener('scroll', this._onScroll, { passive: true });
            this._onScroll();
        },

        /**
         * Обработчик скролла — обновляет translateY каждого слоя.
         * Вызывается через rAF для оптимизации.
         */
        _onScroll() {
            this.lastScroll = window.scrollY;
            requestAnimationFrame(this._apply.bind(this));
        },

        /**
         * Применяет трансформации к слоям.
         * Каждый слой смещается на scrollY * speed вниз.
         */
        _apply() {
            const scrollY = this.lastScroll;
            for (let i = 0; i < this.layers.length; i++) {
                const layer = this.layers[i];
                const speed = parseFloat(layer.dataset.speed) || 0;
                layer.style.transform = 'translateY(' + (scrollY * speed) + 'px)';
            }
        },

        /**
         * Очистка — снятие слушателей.
         */
        destroy() {
            window.removeEventListener('scroll', this._onScroll);
            this.layers = [];
        }
    };

    /* ==========================================================
       2. RIFTLINE — интерактивный split Light/Dark
       ==========================================================
       При движении мыши по hero смещает CSS custom property
       --rift-offset, что двигает clip-path диагонали.
       Диапазон: 35%..65% от ширины hero.
    */
    const RiftLine = {
        /** @type {HTMLElement} */
        hero: null,

        /** @type {HTMLElement} */
        line: null,

        /** @type {boolean} */
        enabled: true,

        /**
         * Инициализация модуля разлома.
         * Привязывает mousemove к hero-секции.
         */
        init() {
            if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
                this.enabled = false;
                return;
            }

            this.hero = document.getElementById('hero');
            this.line = document.getElementById('riftLine');
            if (!this.hero || !this.line) return;

            this._onMouseMove = this._onMouseMove.bind(this);
            this.hero.addEventListener('mousemove', this._onMouseMove, { passive: true });
        },

        /**
         * Обработчик mousemove — вычисляет позицию мыши
         * и обновляет --rift-offset на :root.
         * @param {MouseEvent} e
         */
        _onMouseMove(e) {
            const rect = this.hero.getBoundingClientRect();
            const x = (e.clientX - rect.left) / rect.width;
            // Ограничиваем диапазон 35%..65%
            const percent = 35 + x * 30;
            document.documentElement.style.setProperty('--rift-offset', percent + '%');
        },

        /**
         * Очистка.
         */
        destroy() {
            if (this.hero) {
                this.hero.removeEventListener('mousemove', this._onMouseMove);
            }
        }
    };

    /* ==========================================================
       3. SCROLL REVEAL — появление секций при скролле
       ==========================================================
       Использует IntersectionObserver для добавления класса
       .reveal--visible к элементам с классом .reveal.
       Задержки для карточек задаются через CSS (transition-delay).
    */
    const ScrollReveal = {
        /** @type {IntersectionObserver} */
        observer: null,

        /**
         * Инициализация — создаёт observer и подключает элементы.
         */
        init() {
            if (!('IntersectionObserver' in window)) {
                // Fallback: показать всё
                document.querySelectorAll('.reveal').forEach(function (el) {
                    el.classList.add('reveal--visible');
                });
                return;
            }

            this.observer = new IntersectionObserver(
                this._onIntersect.bind(this),
                {
                    root: null,
                    rootMargin: '0px 0px -60px 0px',
                    threshold: 0.1
                }
            );

            document.querySelectorAll('.reveal').forEach(function (el) {
                ScrollReveal.observer.observe(el);
            });
        },

        /**
         * Callback observer — добавляет класс при пересечении.
         * @param {IntersectionObserverEntry[]} entries
         */
        _onIntersect(entries) {
            for (let i = 0; i < entries.length; i++) {
                if (entries[i].isIntersecting) {
                    entries[i].target.classList.add('reveal--visible');
                    // Прекращаем наблюдение после появления
                    this.observer.unobserve(entries[i].target);
                }
            }
        },

        /**
         * Очистка observer.
         */
        destroy() {
            if (this.observer) {
                this.observer.disconnect();
            }
        }
    };

    /* ==========================================================
       4. CARD TILT — 3D наклон карточек при наведении
       ==========================================================
       Только для desktop (ширина > 768px).
       Применяет perspective() + rotateX/Y к .feature-card.
       При уходе мыши — плавно возвращает в 0.
    */
    const CardTilt = {
        /** @type {boolean} */
        enabled: true,

        /**
         * Инициализация — привязывает обработчики к карточкам.
         */
        init() {
            if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
                this.enabled = false;
                return;
            }
            if (window.innerWidth <= 768) return;

            var cards = document.querySelectorAll('.feature-card');
            for (var i = 0; i < cards.length; i++) {
                this._bindCard(cards[i]);
            }
        },

        /**
         * Привязывает обработчики mousemove/mouseleave к одной карточке.
         * @param {HTMLElement} card
         */
        _bindCard(card) {
            card.addEventListener('mousemove', function (e) {
                var rect = card.getBoundingClientRect();
                var x = (e.clientX - rect.left) / rect.width - 0.5;
                var y = (e.clientY - rect.top) / rect.height - 0.5;
                card.style.transform =
                    'perspective(600px) rotateY(' + (x * 6) + 'deg) ' +
                    'rotateX(' + (-y * 6) + 'deg) ' +
                    'translateY(-6px) scale(1.02)';
                card.style.transition = 'transform 0.08s ease';
            });

            card.addEventListener('mouseleave', function () {
                card.style.transform = 'perspective(600px) rotateY(0) rotateX(0) translateY(0) scale(1)';
                card.style.transition = 'transform 0.4s cubic-bezier(0.22, 1, 0.36, 1)';
            });
        }
    };

    /* ==========================================================
       5. NAV — sticky navbar + burger menu
       ==========================================================
       При скролле > 50px добавляет класс .nav--scrolled.
       Burger toggle для мобильного меню.
       Подсветка активной секции.
    */
    const Nav = {
        /** @type {HTMLElement} */
        nav: null,

        /** @type {HTMLElement} */
        burger: null,

        /** @type {HTMLElement} */
        links: null,

        /** @type {HTMLElement[]} */
        sections: [],

        /**
         * Инициализация навбара.
         */
        init() {
            this.nav = document.getElementById('nav');
            this.burger = document.getElementById('navBurger');
            this.links = document.getElementById('navLinks');

            if (!this.nav) return;

            // Scroll listener для sticky-эффекта
            this._onScroll = this._onScroll.bind(this);
            window.addEventListener('scroll', this._onScroll, { passive: true });
            this._onScroll();

            // Burger menu toggle
            if (this.burger && this.links) {
                this.burger.addEventListener('click', this._toggleBurger.bind(this));
            }

            // Секции для активной навигации
            this.sections = Array.from(document.querySelectorAll('section[id]'));
        },

        /**
         * Обработчик скролла — переключает sticky-класс.
         */
        _onScroll() {
            if (window.scrollY > 50) {
                this.nav.classList.add('nav--scrolled');
            } else {
                this.nav.classList.remove('nav--scrolled');
            }
        },

        /**
         * Toggle burger menu.
         */
        _toggleBurger() {
            var isOpen = this.links.classList.toggle('nav__links--open');
            this.burger.classList.toggle('nav__burger--open', isOpen);
            this.burger.setAttribute('aria-expanded', isOpen);
        },

        /**
         * Очистка.
         */
        destroy() {
            window.removeEventListener('scroll', this._onScroll);
        }
    };

    /* ==========================================================
       ИНИЦИАЛИЗАЦИЯ
       ==========================================================
       Все модули инициализируются после DOMContentLoaded.
    */
    document.addEventListener('DOMContentLoaded', function () {
        Parallax.init();
        RiftLine.init();
        ScrollReveal.init();
        CardTilt.init();
        Nav.init();

        // Лог в консоль для разработчиков
        console.log(
            '%c🍃 Fractured Glade — Landing Ready',
            'color: #9070b0; font-size: 14px; font-weight: bold;'
        );
    });

})();
