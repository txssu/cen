export const CookiesConsent = {
  mounted() {
    this.el
      .querySelector("#accept-cookies-consent")
      .addEventListener("click", () => {
        document.cookie =
          "cookies_consent=accepted; max-age=31536000; path=/; SameSite=Lax";
        console.log("hi");
        this.el.remove();
      });
  },
};
