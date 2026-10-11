// Keep Godot's physical key state correct when releases happen outside its canvas.
(() => {
  const canvas = document.getElementById('canvas');
  const movementCodes = new Set(['KeyA', 'KeyD', 'KeyW', 'KeyS',
    'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown']);
  const held = new Map();
  function release(code, key) {
    canvas.dispatchEvent(new KeyboardEvent('keyup', { code, key, bubbles: true }));
  }
  function clear() {
    const keys = Array.from(held);
    held.clear();
    for (const [code, key] of keys) release(code, key);
  }
  canvas.addEventListener('keydown', event => {
    if (movementCodes.has(event.code)) held.set(event.code, event.key);
  }, true);
  window.addEventListener('keyup', event => {
    if (!held.has(event.code)) return;
    held.delete(event.code);
    if (event.target !== canvas) release(event.code, event.key);
  }, true);
  canvas.addEventListener('blur', clear, true);
  function loseFocus() {
    clear();
    // Godot's Web backend reports canvas focus, whereas application focus
    // notifications are desktop/mobile only. Also pause when the tab is hidden.
    canvas.dispatchEvent(new Event('blur'));
  }
  window.addEventListener('blur', loseFocus);
  window.addEventListener('pagehide', loseFocus);
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) loseFocus();
  });
})();
