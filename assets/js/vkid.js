const VKID = window.VKIDSDK;

export const VKIDOneTap = {
  mounted() {
    VKID.Config.init({
      app: this.el.dataset.clientId,
      redirectUrl: this.el.dataset.redirectUrl,
      responseMode: VKID.ConfigResponseMode.Redirect,
      scope: "vkid.personal_info email phone",
      codeVerifier: this.el.dataset.codeVerifier,
      state: this.el.dataset.state
    });

    const oneTap = new VKID.OneTap();

    oneTap.render({
      container: this.el,
      showAlternativeLogin: true,
      // Fast auth ain't work cause of CORS problem (maybe)
      // So I decided to disable loading
      fastAuthEnabled: false,
      styles: {
        borderRadius: 23,
        height: 46
      }
    })
  }
}
