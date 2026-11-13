{{flutter_js}}
{{flutter_build_config}}
Promise.race([
  window.pulseStartup || Promise.resolve(),
  new Promise(resolve => setTimeout(resolve, 3000))
]).then(() => _flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    } catch (error) {
      window.pulseStartupFailure?.();
      console.error('Flutter engine failed to start', error);
    }
  }
})).catch(error => {
  window.pulseStartupFailure?.();
  console.error('Flutter loader failed to start', error);
});
