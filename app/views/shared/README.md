# UI Components Usage Guide 🎨

This folder contains reusable UI components for consistent styling across the application.

## Button Components

### Primary Button (`buttons/_primary.html.erb`)
Blue background, white text - for main actions.

```erb
<%= render 'shared/buttons/primary', text: "Save Changes" %>
<%= render 'shared/buttons/primary', text: "Submit", type: "submit" %>
<%= render 'shared/buttons/primary', text: "Edit", url: edit_path, size: "small" %>

<!-- Available options: -->
<!-- text: Button text (default: "Button") -->
<!-- size: "small", "medium", "large" (default: "medium") -->
<!-- type: "button", "submit" (default: "button") -->
<!-- url: For link_to usage -->
<!-- method: HTTP method for link_to -->
<!-- disabled: true/false -->
<!-- additional_classes: Custom CSS classes -->
<!-- html_options: Hash of HTML attributes -->
```

### Secondary Button (`buttons/_secondary.html.erb`)
White background with gray border - for secondary actions.

```erb
<%= render 'shared/buttons/secondary', text: "Cancel", url: back_path %>
<%= render 'shared/buttons/secondary', text: "Draft", type: "submit" %>
```

### Tertiary Button (`buttons/_tertiary.html.erb`)
Text-only button - for subtle actions like "Cancel" links.

```erb
<%= render 'shared/buttons/tertiary', text: "Cancel", url: back_path %>
<%= render 'shared/buttons/tertiary', text: "Skip", size: "small" %>
```

## Form Components

### Input Field (`forms/_input.html.erb`)
Standard text input with label, error handling, and consistent styling.

```erb
<%= render 'shared/forms/input',
    form: form,
    field_name: :title,
    model: @model %>

<%= render 'shared/forms/input',
    form: form,
    field_name: :email,
    model: @user,
    input_type: "email",
    placeholder: "Enter your email",
    required: true %>

<!-- Available options: -->
<!-- form: Rails form object -->
<!-- field_name: Symbol of field name -->
<!-- model: Model instance for error checking -->
<!-- label_text: Custom label (defaults to humanized field name) -->
<!-- placeholder: Placeholder text -->
<!-- input_type: "text", "email", "password", etc. (default: "text") -->
<!-- required: true/false -->
<!-- disabled: true/false -->
<!-- show_label: true/false (default: true) -->
<!-- show_errors: true/false (default: true) -->
<!-- additional_classes: Custom CSS classes -->
<!-- html_options: Hash of HTML attributes -->
```

### Text Area (`forms/_text_area.html.erb`)
Multi-line text input with consistent styling and error handling.

```erb
<%= render 'shared/forms/text_area',
    form: form,
    field_name: :description,
    model: @model,
    rows: 6,
    helper_text: "Be as specific as possible." %>

<!-- Additional options beyond input: -->
<!-- rows: Number of rows (default: 4) -->
<!-- helper_text: Helper text shown below field -->
```

## Examples in Action

### Complete Form
```erb
<%= form_with model: @ticket, local: true, class: "space-y-6" do |form| %>
  <%= render 'shared/forms/input',
      form: form,
      field_name: :title,
      model: @ticket,
      required: true %>

  <%= render 'shared/forms/text_area',
      form: form,
      field_name: :description,
      model: @ticket,
      rows: 6,
      helper_text: "Provide detailed information." %>

  <div class="flex justify-between">
    <%= render 'shared/buttons/tertiary',
        text: "Cancel",
        url: tickets_path %>
    <%= render 'shared/buttons/primary',
        text: "Create Ticket",
        type: "submit" %>
  </div>
<% end %>
```

### Button Variations
```erb
<!-- Different sizes -->
<%= render 'shared/buttons/primary', text: "Small", size: "small" %>
<%= render 'shared/buttons/primary', text: "Medium" %>
<%= render 'shared/buttons/primary', text: "Large", size: "large" %>

<!-- Disabled state -->
<%= render 'shared/buttons/primary', text: "Disabled", disabled: true %>

<!-- Custom styling -->
<%= render 'shared/buttons/primary',
    text: "Custom",
    additional_classes: "bg-green-600 hover:bg-green-700" %>
```

## Benefits 🎯

- **Consistency**: All buttons and forms look the same across the app
- **Maintainability**: Change styles in one place
- **Accessibility**: Built-in focus states and proper HTML structure
- **Error Handling**: Automatic error display for form fields
- **Flexibility**: Extensive customization options while maintaining defaults
