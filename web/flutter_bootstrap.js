{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      clearTimeout(window.pulseBootTimer);
      document.getElementById('boot')?.remove();
    } catch (error) {
      const message = document.getElementById('boot-message');
      if (message) message.textContent = '启动失败，请重新加载。';
      const retry = document.getElementById('retry');
      if (retry) retry.hidden = false;
    }
  }
});
