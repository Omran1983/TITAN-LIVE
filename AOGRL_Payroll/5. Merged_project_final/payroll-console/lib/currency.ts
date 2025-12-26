export const formatMUR = (value: number) => {
  return new Intl.NumberFormat('en-MU', {
    style: 'currency',
    currency: 'MUR',
    maximumFractionDigits: 0,
  }).format(value);
};
