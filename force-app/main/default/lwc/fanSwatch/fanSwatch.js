import { api ,LightningElement } from 'lwc';

export default class FanSwatch extends LightningElement {

	@api
    get swatches() {
        const baseClass = 'swatch-outer-circle';
        return this._swatches?.map((swatch) => ({
                ...swatch,
                class: swatch.id === this.selectedId ? `${baseClass} swatch-outer-circle-selected` : `${baseClass}`,
            })
        );
    }

    set swatches(value) {
        this._swatches = value;
    }

	@api
	get selectedId() {
		return this._selectedId;
	}

	set selectedId(value) {
		this._selectedId = value;
	}

	// Local fields.
	_selectedId;
	_swatches;

	handleSwatchClick({ currentTarget }) {

		const { id } = currentTarget.dataset;

		if(this.selectedId !== id) {
			this._selectedId = id;

			this.dispatchEvent(new CustomEvent('change', {
				detail: id
			}));
		}
	}
}