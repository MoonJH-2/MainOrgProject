import { LightningElement } from 'lwc';

export default class CustomBtn extends LightningElement {
  handleClick() {
    alert('Hello World');
  }
}