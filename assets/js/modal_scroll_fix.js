// Modal scroll fix to prevent content jumping
export const ModalScrollFix = {
  mounted() {
    this.updateScrollbarWidth();
    this.resizeHandler = () => this.updateScrollbarWidth();
    window.addEventListener('resize', this.resizeHandler);
  },

  destroyed() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
    }
  },

  updateScrollbarWidth() {
    // Calculate scrollbar width
    const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
    // Set CSS custom property
    document.documentElement.style.setProperty('--scrollbar-width', `${scrollbarWidth}px`);
  }
};