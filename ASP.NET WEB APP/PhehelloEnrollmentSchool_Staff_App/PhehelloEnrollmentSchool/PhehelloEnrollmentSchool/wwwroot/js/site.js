(function () {
  // Show / hide a masked ID number.
  document.querySelectorAll('[data-reveal]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var t = document.getElementById(btn.getAttribute('data-reveal'));
      if (!t) return;
      var shown = t.getAttribute('data-shown') === '1';
      t.textContent = shown ? t.getAttribute('data-mask') : t.getAttribute('data-full');
      t.setAttribute('data-shown', shown ? '0' : '1');
      btn.textContent = shown ? 'Show' : 'Hide';
    });
  });

  // Decision dialog on the Application Review page.
  var dlg = document.getElementById('decisionDialog');
  if (dlg && typeof dlg.showModal === 'function') {
    var title = document.getElementById('dlgTitle');
    var field = document.getElementById('dlgMessageWrap');
    var msg = document.getElementById('dlgMessage');
    var hidden = document.getElementById('dlgDecision');
    var confirmBtn = document.getElementById('dlgConfirm');
    var cfg = {
      approve:     { t: 'Approve this application?', ask: false, label: 'Approve', cls: 'btn btn-gold' },
      corrections: { t: 'Request corrections', ask: true, req: true, label: 'Send request', cls: 'btn btn-brown' },
      reject:      { t: 'Reject this application?', ask: true, req: false, label: 'Reject application', cls: 'btn btn-red' }
    };
    document.querySelectorAll('[data-decision]').forEach(function (b) {
      b.addEventListener('click', function () {
        var c = cfg[b.getAttribute('data-decision')];
        hidden.value = b.getAttribute('data-decision');
        title.textContent = c.t;
        field.style.display = c.ask ? 'block' : 'none';
        document.getElementById('dlgDocsWrap').style.display =b.getAttribute('data-decision') === 'corrections' ? 'block' : 'none';
        document.querySelectorAll('input[name=requestedDocs]').forEach(function (x) { x.checked = false; });
        msg.required = !!c.req;
        msg.value = '';
        confirmBtn.textContent = c.label;
        confirmBtn.className = c.cls;
        dlg.showModal();
      });
    });
    document.getElementById('dlgCancel').addEventListener('click', function () { dlg.close(); });
  }

  // Confirm approving a payment that has no matching school record.
  var approve = document.querySelector('[data-confirm-unmatched]');
  if (approve) approve.addEventListener('click', function (e) {
    if (!confirm('No matching school payment record was found for this reference. Approve anyway?')) e.preventDefault();
  });
})();
