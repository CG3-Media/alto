// Alto JavaScript
// This file handles interactive functionality for the feedback board

document.addEventListener('DOMContentLoaded', function() {
  // Initialize upvote functionality
  initializeUpvoteButtons();

  // Highlight newly created comments
  highlightNewComment();
});

function initializeUpvoteButtons() {
  // Handle upvote button clicks - use capture phase to intercept before Rails UJS
  document.addEventListener('click', function(e) {
    const upvoteButton = e.target.closest('[data-upvote-button]');
    if (!upvoteButton) return;

    // Stop all event propagation to prevent Rails UJS from handling this
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    handleUpvoteClick(upvoteButton);
  }, true); // Use capture phase to run before Rails UJS
}

function handleUpvoteClick(button) {
  const url = button.href;
  const method = button.dataset.method || 'POST';
  const upvotableId = button.dataset.upvotableId;
  const upvotableType = button.dataset.upvotableType;

  // Disable button during request with better visual feedback
  button.style.pointerEvents = 'none';
  button.style.transform = 'scale(0.95)';
  button.style.opacity = '0.7';

  fetch(url, {
    method: method,
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCSRFToken(),
      'Accept': 'application/json'
    }
  })
    .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  })
  .then(data => {
    if (data.error) {
      throw new Error(data.error);
    }

    updateUpvoteButton(button, data.upvoted, data.upvotes_count);
    updateUpvoteUrl(button, data.upvoted);
  })
  .catch(error => {
    console.error('🚨 Upvote error:', error);
    showNotification('Error updating vote. Please try again.', 'error');
  })
  .finally(() => {
    // Re-enable button
    button.style.pointerEvents = '';
    button.style.opacity = '';
    button.style.transform = '';
  });
}

function updateUpvoteButton(button, isUpvoted, upvotesCount) {
  const countElement = button.querySelector('[data-upvote-count]');

  // Update count
  if (countElement) {
    countElement.textContent = upvotesCount;
  }

  // Update button appearance based on new styling
  if (isUpvoted) {
    // Remove unvoted state classes
    button.classList.remove(
      'bg-white', 'text-gray-600', 'border-gray-200',
      'hover:border-blue-400', 'hover:bg-blue-50', 'hover:text-blue-600', 'hover:shadow-md'
    );
    // Add upvoted state classes
    button.classList.add(
      'bg-blue-600', 'text-white', 'border-blue-600',
      'hover:bg-blue-700', 'shadow-lg', 'transform', 'scale-105'
    );
  } else {
    // Remove upvoted state classes
    button.classList.remove(
      'bg-blue-600', 'text-white', 'border-blue-600',
      'hover:bg-blue-700', 'shadow-lg', 'transform', 'scale-105'
    );
    // Add unvoted state classes
    button.classList.add(
      'bg-white', 'text-gray-600', 'border-gray-200',
      'hover:border-blue-400', 'hover:bg-blue-50', 'hover:text-blue-600', 'hover:shadow-md'
    );
  }

  // Always use DELETE for toggle URLs - the backend toggle action handles both add/remove
  button.dataset.method = 'DELETE';
}

function updateUpvoteUrl(button, isUpvoted) {
  // For toggle URLs, we always use DELETE method since toggle handles both add/remove
  // The URL stays the same - it's always the toggle endpoint
  button.dataset.method = 'DELETE';


}

function getCSRFToken() {
  const metaTag = document.querySelector('meta[name="csrf-token"]');
  return metaTag ? metaTag.content : '';
}

function showNotification(message, type = 'info') {
  // Simple notification system
  const notification = document.createElement('div');
  notification.className = `fixed top-4 right-4 px-4 py-2 rounded-md text-white text-sm z-50 ${
    type === 'error' ? 'bg-red-500' : 'bg-blue-500'
  }`;
  notification.textContent = message;

  document.body.appendChild(notification);

  // Auto-remove after 3 seconds
  setTimeout(() => {
    notification.remove();
  }, 3000);
}



function highlightNewComment() {
  // Check if there's a hash in the URL (anchor)
  if (window.location.hash) {
    const commentId = window.location.hash.substring(1); // Remove the #
    const commentElement = document.getElementById(commentId);

    if (commentElement && commentId.startsWith('comment-')) {
      // Add highlight styling
      const commentContainer = commentElement.querySelector('div');
      if (commentContainer) {
        commentContainer.classList.add('bg-blue-50', 'border-2', 'border-blue-200', 'rounded-md');

        // Remove highlighting after 3 seconds
        setTimeout(() => {
          commentContainer.classList.remove('bg-blue-50', 'border-2', 'border-blue-200', 'rounded-md');
        }, 3000);
      }
    }
  }
}
