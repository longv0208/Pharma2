(function () {
    'use strict';

    var printButton = document.getElementById('print-policies');
    if (printButton) {
        printButton.hidden = false;
        printButton.addEventListener('click', function () {
            window.print();
        });
    }

    // Include collapsed policy text when the browser prints the page.
    var openedForPrint = [];
    window.addEventListener('beforeprint', function () {
        openedForPrint = Array.from(document.querySelectorAll('.about-accordion details:not([open])'));
        openedForPrint.forEach(function (detail) { detail.open = true; });
    });
    window.addEventListener('afterprint', function () {
        openedForPrint.forEach(function (detail) { detail.open = false; });
        openedForPrint = [];
    });

    var navigationLinks = document.querySelectorAll('.about-toc > a');
    var sections = document.querySelectorAll('.about-section');
    function updateCurrentSection() {
        var currentId = sections[0].id;
        var header = document.querySelector('.site-header');
        var sectionOffset = parseFloat(window.getComputedStyle(sections[0]).scrollMarginTop);
        var headerBottom = Math.max(header.getBoundingClientRect().bottom + 45, sectionOffset + 2);
        sections.forEach(function (section) {
            if (section.getBoundingClientRect().top <= headerBottom) {
                currentId = section.id;
            }
        });
        navigationLinks.forEach(function (link) {
            if (link.getAttribute('href') === '#' + currentId) {
                link.setAttribute('aria-current', 'location');
            } else {
                link.removeAttribute('aria-current');
            }
        });
    }
    window.addEventListener('scroll', updateCurrentSection, { passive: true });
    window.addEventListener('resize', updateCurrentSection);
    updateCurrentSection();
}());
