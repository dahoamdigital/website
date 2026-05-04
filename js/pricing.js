/**
 * Einzige Quelle für Website-Paketpreise (Klein/Mittel/Groß).
 * index.html und preise.html lesen diese Werte per applyPricingToDom().
 */
(function () {
  var PAKETE = {
    starter: { name: 'Klein', monat: 14, einmalig: 99 },
    standard: { name: 'Mittel', monat: 39, einmalig: 199 },
    premium: { name: 'Groß', monat: 69, einmalig: 399 },
  };

  function str(n) {
    return String(n);
  }

  function applyPricingToDom() {
    var k = PAKETE.starter;
    document.querySelectorAll('[data-dahoam-ab-monat]').forEach(function (el) {
      el.textContent = str(k.monat);
    });

    ['starter', 'standard', 'premium'].forEach(function (code) {
      var p = PAKETE[code];
      var mEl = document.getElementById('preis-' + code + '-monat');
      var eEl = document.getElementById('preis-' + code + '-einmalig');
      if (mEl) mEl.textContent = str(p.monat);
      if (eEl) eEl.textContent = str(p.einmalig);
    });

    var sel = document.getElementById('kf-paket-wunsch');
    if (sel) {
      for (var i = 0; i < sel.options.length; i++) {
        var opt = sel.options[i];
        var code = opt.value;
        var x = PAKETE[code];
        if (!x) continue;
        opt.text =
          x.name +
          ' – ' +
          x.monat +
          '\u00a0€/Monat + ' +
          x.einmalig +
          '\u00a0€ einmalig';
      }
    }

    var metaIndex = document.getElementById('dahoam-meta-description');
    if (metaIndex) {
      metaIndex.setAttribute(
        'content',
        'Dahoam-Digital: Einstieg in die digitale Welt – Website-Pakete ab ' +
          k.monat +
          ' €/Monat plus einmalige Inbetriebnahme. Design, Hosting, Domain. Fair kalkuliert; aus Weiz.'
      );
    }

    var metaPreise = document.getElementById('dahoam-preise-meta-description');
    if (metaPreise) {
      metaPreise.setAttribute(
        'content',
        'Drei Website-Pakete: Abo ab ' +
          k.monat +
          ' €/Monat je nach Größe plus einmalige Inbetriebnahme (' +
          PAKETE.starter.einmalig +
          '–' +
          PAKETE.premium.einmalig +
          ' €). Hosting, Domain, Festpreis beim Start. Dahoam-Digital, Steiermark.'
      );
    }
  }

  window.DahoamPaketpreise = PAKETE;
  window.DahoamApplyPaketpreise = applyPricingToDom;

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applyPricingToDom);
  } else {
    applyPricingToDom();
  }
})();
