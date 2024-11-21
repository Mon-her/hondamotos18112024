import { api, LightningElement } from 'lwc';

const Event = {
  // Buttons -> click events.
  DECREASE: 'quantitydecrease',
  INCREASE: 'quantityincrease',
  // Buttons -> blur events after click event.
  DECREASED: 'quantitydecreased',
  INCREASED: 'quantityincreased',
  // Quantity input -> any change.
  CHANGE: 'quantitychange',
  // Quantity input -> blur event.
  CHANGED: 'quantitychanged'
};

export default class FanQuantityHandler extends LightningElement {
  /**
    * An event fired when the quantity of an item changes.
    *
    * @event QuantityHandler#quantitychange
    * @type {CustomEvent}
    *
    * @property {string} detail.itemId
    *   The unique identifier of an item.
    *
    * @property {number} detail.quantity
    *   The new quantity of the item.
    *
    * @export
    */

  /**
    * An event fired when the quantity of an item has been changed.
    *
    * @event QuantityHandler#quantitychanged
    * @type {CustomEvent}
    *
    * @property {string} detail.itemId
    *   The unique identifier of an item.
    *
    * @property {number} detail.quantity
    *   The new quantity of the item.
    *
    * @export
    */

  /**
    * An event fired when the quantity of an item decreases.
    *
    * @event QuantityHandler#quantitydecrease
    * @type {CustomEvent}
    *
    * @property {string} detail.itemId
    *   The unique identifier of an item.
    *
    * @property {number} detail.quantity
    *   The new quantity of the item.
    *
    * @export
    */

  /**
    * An event fired when the quantity of an item has been decreased.
    *
    * @event QuantityHandler#quantitydecreased
    * @type {CustomEvent}
    *
    * @property {string} detail.itemId
    *   The unique identifier of an item.
    *
    * @property {number} detail.quantity
    *   The new quantity of the item.
    *
    * @export
    */

  /**
    * An event fired when the quantity of an item increases.
    *
    * @event QuantityHandler#quantityincrease
    * @type {CustomEvent}
    *
    * @property {string} detail.itemId
    *   The unique identifier of an item.
    *
    * @property {number} detail.quantity
    *   The new quantity of the item.
    *
    * @export
    */

  /**
    * An event fired when the quantity of an item has been increased.
    *
    * @event QuantityHandler#quantityincreased
    * @type {CustomEvent}
    *
    * @property {string} detail.itemId
    *   The unique identifier of an item.
    *
    * @property {number} detail.quantity
    *   The new quantity of the item.
    *
    * @export
    */

	/**
	 * Set or get the item id 
	*/
	@api
	itemId;

	/**
	 * Set or get the minimum value for the quantity
	*/
	@api
	set min(value) {
		this._min = Number(value);
	}

	get min() {
		return this._min;
	}

	/**
	 * Set or get the maximum value for the quantity
	*/
	@api
	set max(value) {
		this._max = Number(value);
	}

	get max() {
		return this._max;
	}

	/**
	 * Set or get the quantity value
	*/
	@api
	set value(value) {
		this._value = Number(value);
	}

	get value() {
		return this._value;
	}

	/**
	 * Set or get the quantity label
	*/
	@api
	label;

	@api
	disabled;

	// Local variables.
  _max;
  _min;
	_value;

	/**
	 * Control when to disable  the 'Decrease quantity' button
	 * @private
	 * @readonly
	 */
	get disableQuantityDecrease() {
		return this.disabled || this.value <= this.min;
	}

	/**
	 * Control when to disable  the 'Increase quantity' button
	 * @private
	 * @readonly
	 */
	get disableQuantityIncrease() {
		return this.disabled || this.value >= this.max;
	}

  get inputElement() {
    return this.template.querySelector('[name="quantityInput"]');
  }

  /**
   * Fires an event when "Decrease quantiy" button is clicked.
   * @private
   * @fires Quantity#decrease
   */
	handleQuantityDecrease() {
    this.anyButtonClicked = true;
    --this._value;
    this.fireEvents([Event.DECREASE, Event.CHANGE]);
	}

  /**
   * Fires an event when "Decrease Quantiy" button loses focus after a decrease in quantity.
   * @private
   * @fires Quantity#decreased
   */
	handleQuantityDecreased() {
    if (this.anyButtonClicked) {
      this.anyButtonClicked = false;
      this.fireEvents([Event.DECREASED, Event.CHANGED]);
    }
	}

  handleForbiddenCharacters(event) {
    if (event.data && !/^[0-9]+$/.test(event.data)) {
      event.preventDefault();
    }
  }

  handleQuanityInput({ target }) {
    const quantity = target.valueAsNumber;

    if (isNaN(quantity)) {
      return;
    } else if (quantity < this.min) {
      this.inputElement.value = this.min;
    } else if(quantity > this.max) {
      this.inputElement.value = this.value;
    } else if (quantity !== this.value) {
      this._value = quantity;
      this.fireEvents([Event.CHANGE]);
    }
    this.quantityChanged = true;
  }

  handleInputBlur({ target }) {
    const quantity = target.valueAsNumber || this.min;
    const oldValue = this.value;
    this.inputElement.value = quantity;

    if(this.quantityChanged || quantity !== oldValue) {
      this.quantityChanged = false;
      this._value = quantity;
      this.fireEvents([Event.CHANGED])
    }

    if(quantity !== oldValue) {
      this.fireEvents([Event.CHANGE])
    }
  }

  /**
    * Fires an event when "Increase quantiy" button is clicked.
    * @private
    * @fires Quantity#increase
    */
	handleQuantityIncrease() {
    this.anyButtonClicked = true;
    ++this._value;
    this.fireEvents([Event.INCREASE, Event.CHANGE]);
	}

  /**
    * Fires an event when "Increase quantiy" button loses focus after an increase in quantity.
    * @private
    * @fires Quantity#increased
    */
	handleQuantityIncreased() {
    if (this.anyButtonClicked) {
      this.anyButtonClicked = false;
      this.fireEvents([Event.INCREASED, Event.CHANGED]);
    }
	}

  fireEvents(eventNames) {
    const payload = {
      detail: {
        itemId: this.itemId,
        quantity: this.value
      }
    };
    eventNames.forEach((eventName) => 
      this.dispatchEvent(new CustomEvent(eventName, payload))
    );
  }
}