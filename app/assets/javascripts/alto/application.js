// Alto JavaScript
// This file handles interactive functionality for the feedback board

document.addEventListener('DOMContentLoaded', function() {
  // Initialize upvote functionality
  initializeUpvoteButtons();

  // Highlight newly created comments
  highlightNewComment();
});

function initializeUpvoteButtons() {
  // Handle upvote button clicks
  document.addEventListener('click', function(e) {
    const upvoteButton = e.target.closest('[data-upvote-button]');
    if (!upvoteButton) return;

    e.preventDefault();
    handleUpvoteClick(upvoteButton);
  });
}

function handleUpvoteClick(button) {
  const url = button.href;
  const method = button.dataset.method || 'POST';
  const upvotableId = button.dataset.upvotableId;
  const upvotableType = button.dataset.upvotableType;

  // Debug logging (uncomment for troubleshooting)
  // console.log('🎯 Upvote click detected:', {
  //   url: url,
  //   method: method,
  //   upvotableId: upvotableId,
  //   upvotableType: upvotableType,
  //   buttonElement: button
  // });

  // Disable button during request
  button.style.pointerEvents = 'none';
  button.style.opacity = '0.6';

  fetch(url, {
    method: method,
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCSRFToken(),
      'Accept': 'application/json'
    }
  })
    .then(response => {
    // Debug logging (uncomment for troubleshooting)
    // console.log('🌐 Response received:', {
    //   status: response.status,
    //   statusText: response.statusText,
    //   url: response.url
    // });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  })
  .then(data => {
    // Debug logging (uncomment for troubleshooting)
    // console.log('📦 Response data:', data);

    if (data.error) {
      throw new Error(data.error);
    }

    updateUpvoteButton(button, data.upvoted, data.upvotes_count);
    updateUpvoteUrl(button, data.upvoted);

    // Debug logging (uncomment for troubleshooting)
    // console.log('✅ Upvote update completed successfully');
  })
  .catch(error => {
    console.error('🚨 Upvote error:', error);
    showNotification('Error updating vote. Please try again.', 'error');
  })
  .finally(() => {
    // Re-enable button
    button.style.pointerEvents = '';
    button.style.opacity = '';
  });
}

function updateUpvoteButton(button, isUpvoted, upvotesCount) {
  const countElement = button.querySelector('[data-upvote-count]');
  const iconElement = button.querySelector('svg');

  // Update count
  if (countElement) {
    countElement.textContent = upvotesCount;
  }

  // Update button appearance
  if (isUpvoted) {
    button.classList.remove('text-gray-400', 'hover:text-blue-600', 'hover:bg-blue-50');
    button.classList.add('bg-blue-50', 'text-blue-600', 'hover:bg-blue-100');
  } else {
    button.classList.remove('bg-blue-50', 'text-blue-600', 'hover:bg-blue-100');
    button.classList.add('text-gray-400', 'hover:text-blue-600', 'hover:bg-blue-50');
  }

  // Always use DELETE for toggle URLs - the backend toggle action handles both add/remove
  button.dataset.method = 'DELETE';
}

function updateUpvoteUrl(button, isUpvoted) {
  // For toggle URLs, we always use DELETE method since toggle handles both add/remove
  // The URL stays the same - it's always the toggle endpoint
  button.dataset.method = 'DELETE';

  // Debug logging (uncomment for troubleshooting)
  // console.log('Updated upvote button:', {
  //   url: button.href,
  //   method: button.dataset.method,
  //   upvotableId: button.dataset.upvotableId,
  //   upvotableType: button.dataset.upvotableType,
  //   isUpvoted: isUpvoted
  // });
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
