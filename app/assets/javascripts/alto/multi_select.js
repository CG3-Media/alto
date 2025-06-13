// Alto Multi-Select Component
// Generic multi-select functionality for any type of items (tags, users, etc.)

document.addEventListener('DOMContentLoaded', function() {
  // Initialize all multi-select components on the page
  document.querySelectorAll('[data-multi-select]').forEach(container => {
    initializeMultiSelect(container);
  });
});

function initializeMultiSelect(container) {
  const searchInput = container.querySelector('.item-search-input');
  const inputContainer = container.querySelector('.multi-select-container');
  const dropdown = container.querySelector('.multi-select-dropdown');
  const chipsContainer = container.querySelector('.selected-chips-container');

  if (!searchInput || !inputContainer || !dropdown) {
    console.error('Multi-select missing required elements');
    return;
  }

  // Get configuration from data attributes
  const modelName = container.dataset.modelName;
  const fieldName = container.dataset.fieldName;
  const itemValueMethod = container.dataset.itemValueMethod || 'id';
  const itemDisplayMethod = container.dataset.itemDisplayMethod || 'name';

  // Track selected values
  let selectedValues = new Set();
  try {
    const initialValues = JSON.parse(inputContainer.dataset.selectedValues || '[]');
    selectedValues = new Set(initialValues.map(v => String(v)));
  } catch (e) {
    console.error('Error parsing selected values:', e);
  }

  // Dropdown state management
  let isDropdownOpen = false;

  function showDropdown() {
    dropdown.classList.remove('hidden');
    isDropdownOpen = true;
  }

  function hideDropdown() {
    dropdown.classList.add('hidden');
    isDropdownOpen = false;
  }

  // Focus handling
  searchInput.addEventListener('focus', showDropdown);
  searchInput.addEventListener('click', showDropdown);

  searchInput.addEventListener('blur', () => {
    // Delay to allow clicks on dropdown items
    setTimeout(() => {
      if (!container.contains(document.activeElement)) {
        hideDropdown();
      }
    }, 150);
  });

  // Click on container focuses search input
  inputContainer.addEventListener('click', (e) => {
    if (e.target === inputContainer || e.target.closest('.selected-item-chip')) {
      searchInput.focus();
    }
  });

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!container.contains(e.target)) {
      hideDropdown();
    }
  });

  // Search functionality
  searchInput.addEventListener('input', function() {
    const searchTerm = this.value.toLowerCase();
    const options = dropdown.querySelectorAll('.item-option');

    options.forEach(option => {
      const searchText = option.dataset.itemSearch || option.dataset.itemDisplay || '';
      const matches = searchText.toLowerCase().includes(searchTerm);
      option.style.display = matches ? '' : 'none';
    });
  });

  // Handle item selection
  dropdown.addEventListener('click', (e) => {
    const option = e.target.closest('.item-option');
    if (!option || option.classList.contains('pointer-events-none')) return;

    const itemValue = option.dataset.itemValue;
    const itemDisplay = option.dataset.itemDisplay;
    const itemIcon = option.dataset.itemIcon;

    if (!itemValue) return;

    // Add the item
    addSelectedItem({
      value: itemValue,
      display: itemDisplay,
      icon: itemIcon
    });

    // Update UI
    selectedValues.add(itemValue);
    option.classList.add('opacity-50', 'pointer-events-none');

    // Clear search and update placeholder
    searchInput.value = '';
    searchInput.placeholder = 'Add more...';
  });

  // Add a selected item chip
  function addSelectedItem(itemData) {
    // Clone the template
    const template = chipsContainer.querySelector('.template-item');
    if (!template) return;

    const newChip = template.cloneNode(true);
    newChip.classList.remove('template-item');
    newChip.style.display = '';
    newChip.dataset.itemValue = itemData.value;

    // Update chip content
    const chipDisplay = newChip.querySelector('.chip-display');
    const chipText = newChip.querySelector('.chip-text');
    const chipIcon = newChip.querySelector('.chip-icon');
    const valueInput = newChip.querySelector('.item-value-input');

    if (chipText) chipText.textContent = itemData.display;
    if (valueInput) valueInput.value = itemData.value;

    // Apply icon if available
    if (chipIcon && itemData.icon) {
      chipIcon.textContent = itemData.icon;
    } else if (chipIcon && !itemData.icon) {
      chipIcon.style.display = 'none';
    }

    // Add remove functionality
    const removeBtn = newChip.querySelector('.chip-remove-btn');
    if (removeBtn) {
      removeBtn.addEventListener('click', () => {
        removeSelectedItem(newChip, itemData.value);
      });
    }

    // Append to container
    chipsContainer.appendChild(newChip);
  }

  // Remove a selected item
  function removeSelectedItem(chipElement, itemValue) {
    // Remove the chip
    chipElement.remove();

    // Update tracking
    selectedValues.delete(itemValue);

    // Re-enable the option in dropdown
    const option = dropdown.querySelector(`[data-item-value="${itemValue}"]`);
    if (option) {
      option.classList.remove('opacity-50', 'pointer-events-none');
    }

    // Update placeholder if no items selected
    if (selectedValues.size === 0) {
      searchInput.placeholder = container.dataset.placeholder || 'Search and select...';
    }

    // Keep focus on search input
    searchInput.focus();
  }

  // Initialize remove buttons for existing chips
  chipsContainer.querySelectorAll('.selected-item-chip:not(.template-item)').forEach(chip => {
    const removeBtn = chip.querySelector('.chip-remove-btn');
    const itemValue = chip.dataset.itemValue;

    if (removeBtn && itemValue) {
      removeBtn.addEventListener('click', () => {
        removeSelectedItem(chip, itemValue);
      });
    }
  });

  // Keyboard navigation support
  let highlightedIndex = -1;
  const getVisibleOptions = () => Array.from(dropdown.querySelectorAll('.item-option:not([style*="display: none"]):not(.pointer-events-none)'));

  searchInput.addEventListener('keydown', (e) => {
    const visibleOptions = getVisibleOptions();

    switch(e.key) {
      case 'ArrowDown':
        e.preventDefault();
        highlightedIndex = Math.min(highlightedIndex + 1, visibleOptions.length - 1);
        updateHighlight(visibleOptions);
        break;

      case 'ArrowUp':
        e.preventDefault();
        highlightedIndex = Math.max(highlightedIndex - 1, -1);
        updateHighlight(visibleOptions);
        break;

      case 'Enter':
        e.preventDefault();
        if (highlightedIndex >= 0 && visibleOptions[highlightedIndex]) {
          visibleOptions[highlightedIndex].click();
          highlightedIndex = -1;
        }
        break;

      case 'Escape':
        hideDropdown();
        searchInput.blur();
        break;
    }
  });

  function updateHighlight(options) {
    options.forEach((option, index) => {
      if (index === highlightedIndex) {
        option.classList.add('bg-gray-100');
      } else {
        option.classList.remove('bg-gray-100');
      }
    });
  }

  console.log('Multi-select initialized for', modelName, 'with', selectedValues.size, 'selected items');
}
