{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      // The Dart bootstrap signals readiness after content and preferences
      // have loaded and the first actual page has been painted.
    } catch (error) {
      const message = document.getElementById('boot-message');
      if (message) message.textContent = '启动失败，请重新加载。';
      const retry = document.getElementById('retry');
      if (retry) retry.hidden = false;
    }
  }
});
