import getMotosAvailability from '@salesforce/apex/fan_OCIGetAvailability.getMotosAvailability';
import getPosventaAvailability from '@salesforce/apex/fan_OCIGetAvailability.getPosventaAvailability';

const STORE = { MOTOS: 'motos' };

function sortCartItemResultsByIdAscing(cartItemResults = []) {
	return [...cartItemResults].sort(({ cartItem: a }, { cartItem: b }) => {
		return a.productId.localeCompare(b.productId);
	});
}

export function getAvailability(storeName, communityId, cartItemResults) {
	const sortedCartItemResults = sortCartItemResultsByIdAscing(cartItemResults ?? []);

	return storeName === STORE.MOTOS
	? fetchMotosAvailability(sortedCartItemResults)
	: fetchPosventaAvailability(communityId, sortedCartItemResults);
}

async function fetchMotosAvailability(cartItemResults) {
	let skusByCity = cartItemResults.reduce((accumulator, { cartItem }) => {
		const { sku} = cartItem.productDetails;
		const { DeliverToCity } = cartItem.cartDeliveryGroup;

		const skus = accumulator[DeliverToCity] ?? new Set();
		skus.add(sku);
		accumulator[DeliverToCity] = skus;
		return accumulator;
	}, {});
	skusByCity = Object.entries(skusByCity).reduce((accumulator, [city, skus]) => {
		accumulator[city] = [...skus];
		return accumulator;
	}, {});

	try {
		const availability = await getMotosAvailability({ skusByCity });
		return JSON.parse(availability);
	} catch (error) {
		console.log('Error in fetchMotosAvailability -->', error);
		return {};
	}
}

async function fetchPosventaAvailability(communityId, cartItemResults) {
	try {
		const skus = cartItemResults.map(({ cartItem }) => cartItem.productDetails.sku);
		return getPosventaAvailability({ communityId, skus });
	} catch (error) {
		console.log('Error in fetchPosventaAvailability -->', error);
		return {};
	}
}

export function hasAvailability(storeName, cartItemResults, skusAvailability) {
	const sortedCartItemResults = sortCartItemResultsByIdAscing(cartItemResults);

	return storeName === STORE.MOTOS
	? hasMotosAvailability(sortedCartItemResults, skusAvailability)
	: hasPosventaAvailability(sortedCartItemResults, skusAvailability);
}

function hasMotosAvailability(cartItemResults, skusAvailabilityByCity) {
	const pasredSkusAvailability = JSON.parse(JSON.stringify(skusAvailabilityByCity));
	return cartItemResults.some(({ cartItem }) => {
		const { sku } = cartItem.productDetails;
		const { DeliverToCity } = cartItem.cartDeliveryGroup;
		const skusAvailability = pasredSkusAvailability[DeliverToCity];

		const orderedQuantity = Number(cartItem.quantity);
		return extractAvailability(skusAvailability, sku, orderedQuantity);
	});
}
	
function hasPosventaAvailability(cartItemResults, availability) {
	const skusAvailability = JSON.parse(JSON.stringify(availability));
	return cartItemResults.some(({ cartItem }) => {
		const { sku } = cartItem.productDetails;
		const orderedQuantity = Number(cartItem.quantity);

		return extractAvailability(skusAvailability, sku, orderedQuantity);
	});
}

export function extractAvailability(skusAvailability, sku, orderedQuantity) {
	if(!skusAvailability[sku]) {
		skusAvailability[sku] = { available: 0, substitutes: [] };
	}
	let { available, substitutes } = skusAvailability[sku];
	// Quantity that can be ordered. 
	let elegibleQuantity = Math.min(available, orderedQuantity);
	// Update sku availability.
	skusAvailability[sku].available -= elegibleQuantity;
	if(substitutes.length) {
		// Get quantity from related products to complete the requested.
		elegibleQuantity += extractAvailabilityFromSubstitutes(skusAvailability, substitutes, orderedQuantity, elegibleQuantity);
	}
	return elegibleQuantity;
}

function extractAvailabilityFromSubstitutes(skusAvailability, substitutes, orderedQuantity, elegibleQuantity) {
	let extractedTotalAvailability = 0;
	const iterator = substitutes.values();
	let sku;
	while (elegibleQuantity < orderedQuantity && !(sku = iterator.next()).done) {
		// Quantity needed to complete the request.
		const requiredQuantity = orderedQuantity - elegibleQuantity;
		const { available } = skusAvailability[sku.value];
		// Quantity that can be extracted from the related product. 
		const extractedAvailability = Math.min(available, requiredQuantity);
		extractedTotalAvailability += extractedAvailability;
		elegibleQuantity += extractedAvailability;

		skusAvailability[sku.value].available -= extractedAvailability;
	}
	return extractedTotalAvailability;
}