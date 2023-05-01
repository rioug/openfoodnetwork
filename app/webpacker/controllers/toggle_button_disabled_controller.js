import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["button"];

  connect() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true;
    }
  }

  inputIsChanged(e) {
    if (e.target.value !== "") {
      this.buttonTarget.disabled = false;
    } else {
      this.buttonTarget.disabled = true;
    }
  }
}
