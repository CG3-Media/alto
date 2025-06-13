# Examples of using the generic multi-select component

# 1. Tags with colors (as used in tickets)
<%= render 'alto/shared/forms/multi_select',
    form: form,
    model: @ticket,
    field_name: :tag_ids,
    available_items: @board.tags.ordered,
    selected_items: @ticket.tags,
    label: "Tags",
    item_display_method: :name %>

# 2. Assigning users to a project
<%= render 'alto/shared/forms/multi_select',
    form: form,
    model: @project,
    field_name: :user_ids,
    available_items: User.active,
    selected_items: @project.users,
    label: "Team Members",
    placeholder: "Search users by name or email...",
    item_display_method: :name,
    item_subtitle_method: :email,
    item_icon_method: :avatar_emoji %>  # If users have avatar emojis

# 3. Categories without form builder
<%= render 'alto/shared/forms/multi_select',
    model: @product,
    field_name: :category_ids,
    available_items: Category.all,
    selected_items: @product.categories,
    label: "Product Categories",
    item_display_method: :title,
    item_search_method: :full_path,  # Search by full category path
    empty_message: "No categories available" %>

# 4. Simple selection without search
<%= render 'alto/shared/forms/multi_select',
    form: form,
    model: @post,
    field_name: :topic_ids,
    available_items: Topic.published,
    selected_items: @post.topics,
    label: "Topics",
    show_search: false,  # No search for small lists
    max_height: "max-h-40" %>

# 5. Read-only display
<%= render 'alto/shared/forms/multi_select',
    model: @ticket,
    field_name: :tag_ids,
    selected_items: @ticket.tags,
    label: "Assigned Tags",
    item_display_method: :name %>

# 6. With custom help text
<%= render 'alto/shared/forms/multi_select',
    form: form,
    model: @article,
    field_name: :author_ids,
    available_items: Author.verified,
    selected_items: @article.authors,
    label: "Authors",
    help_text: "Select all authors who contributed to this article",
    item_display_method: :full_name,
    item_subtitle_method: :bio_summary %>

# 7. Minimal configuration (uses all defaults)
<%= render 'alto/shared/forms/multi_select',
    form: form,
    model: @item,
    available_items: @available_options,
    selected_items: @item.options %>
