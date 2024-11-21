import { resolve } from 'c/fanCmsResourceResolver';

function mapVariants({ id, swatch, defaultImage, fields }) {
    defaultImage = defaultImage ?? {};
    return {
        id,
        swatch,
        fields: fields.filter((value) => !!value),
        image: {
            url: resolve(defaultImage.url),
            alternateText: defaultImage.alternateText ?? ''
        }
    };
}

/**
 * Transform product search API response data into display-data.
 *
 * @param {ConnectApi.ProductSummaryPage} data
 * @param {string} cardContentMapping
 */
export function transformData(data) {
    const DEFAULT_PAGE_SIZE = 20;
    const { productsPage = {}, categories = {}, facets = [], locale = '' } =
        data ?? {};
    const {
        total = 0,
        products = {},
        pageSize = DEFAULT_PAGE_SIZE
    } = productsPage;

    return {
        locale,
        total,
        pageSize,
        categoriesData: categories,
        facetsData: facets.map(
            ({
                nameOrId,
                attributeType,
                facetType: type,
                displayType,
                displayName,
                displayRank,
                values
            }) => {
                return {
                    // include a unique identifier to avoid the collision
                    // between Product2 and variant custom fields
                    id: `${nameOrId}:${attributeType}`,
                    nameOrId,
                    attributeType,
                    type,
                    displayType,
                    displayName,
                    displayRank,
                    values: values.map((v) => ({ ...v, checked: false }))
                };
            }
        ),
        /* Product list normalization */
        layoutData: Object.entries(products).map(([variantParentId, variants]) => ({
            variantParentId,
            variants: variants.map(mapVariants)
        }))
    };
}

export function setPrices(productPrices, currencyIsoCode) {
    return ({ variantParentId, variants }) =>  ({
        variantParentId,
        variants: variants.map((product) => ({
            ...product,
            prices: {
                listPrice: productPrices[product.id] ?? 0,
                currencyIsoCode
            }
        }))
    });
}

/**
 * Gets the normalized card content mapping fields.
 * @param {string} cardContentMapping comma separated fields
 * @returns {string[]}
 */
export function normalizedCardContentMapping(cardContentMapping) {
    return (cardContentMapping ?? 'Name').split(',');
}