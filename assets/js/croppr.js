import Croppr from "../vendor/croppr.js";

function cropprToBlob(el, { height, width, x, y }, callback) {
  const canvas = document.createElement("canvas");
  const context = canvas.getContext("2d");
  canvas.width = width;
  canvas.height = height;
  context.drawImage(el, x, y, width, height, 0, 0, canvas.width, canvas.height);
  canvas.toBlob(callback, "image/jpeg", 0.9);
}

function initializeCroppr(hook, file) {
  hook.clean({ name: hook.el.dataset.uploadName });
  hook.hideClickableArea();

  hook.img = new Image();
  hook.img.src = URL.createObjectURL(file);
  hook.el.appendChild(hook.img);

  const uploadBlob = (blob) => hook.upload(hook.el.dataset.uploadName, [blob])

  hook.croppr = new Croppr(hook.img, {
    aspectRatio: 1,
    minSize: [100, 100, "px"],
    onInitialize: (instance) => cropprToBlob(hook.img, instance.getValue(), uploadBlob),
    onCropEnd: (vals) => cropprToBlob(hook.img, vals, uploadBlob),
  });

  hook.showDeleteButton();
}

function handleFileSelect(hook, file) {
  if (file) {
    initializeCroppr(hook, file);
  }
}

function handleFileDrop(hook, event) {
  event.preventDefault();
  const files = Array.from(event.dataTransfer.files || []);
  if (files.length > 0) {
    handleFileSelect(hook, files[0]);
  }
}

function handleFileClick(hook) {
  const input = document.createElement('input');
  input.type = 'file';
  input.onchange = (e) => handleFileSelect(hook, e.target.files[0]);
  input.click();
}

function handleDeleteClick(hook) {
  hook.clean({ name: hook.el.dataset.uploadName });
  hook.showClickableArea();
  hook.hideDeleteButton();
  hook.pushEvent("delete_image", { ref: hook.el.dataset.uploadRef });
}

const Hook = {
  mounted() {
    this.handleEvent("croppr:destroy", this.clean);

    this.el.addEventListener("dragover", (e) => e.preventDefault());
    this.el.addEventListener("drop", (e) => handleFileDrop(this, e));
    this.el.querySelector(".croppr-clickable-area").addEventListener("click", () => handleFileClick(this));

    this.deleteButton = this.el.querySelector(".croppr-delete-button");
    this.deleteButton.addEventListener("click", () => handleDeleteClick(this));

    if (this.el.dataset.uploadedImage) {
      this.showDeleteButton();
      fetch(this.el.dataset.uploadedImage)
        .then((response) => response.blob())
        .then((blob) => initializeCroppr(this, blob));
    }
  },

  destroyed() {
    this.croppr && this.croppr.destroy();
  },

  clean({ name }) {
    if (name === this.el.dataset.uploadName) {
      if (this.croppr) {
        this.croppr.destroy();
        this.img && this.el.removeChild(this.img);
        this.img && URL.revokeObjectURL(this.img.src);
        this.img = null;
        this.croppr = null;
      }
    }
  },

  showClickableArea() {
    this.el.querySelector(".croppr-clickable-area").classList.remove("hidden");
  },

  hideClickableArea() {
    this.el.querySelector(".croppr-clickable-area").classList.add("hidden");
  },

  showDeleteButton() {
    this.deleteButton.classList.remove("hidden");
  },

  hideDeleteButton() {
    this.deleteButton.classList.add("hidden");
  },
};

export default Hook;
