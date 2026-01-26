# Component Guidelines

## About

This serves as the reference documentation for components in PlaceCal (how to generate them etc).

In case you find something unclear, inaccurate or out of date, please feel to create a new issue describing what needs doing :smile:

## Technical Details

PlaceCal uses [ViewComponent](https://viewcomponent.org/) for all components.

### Creating a new component

[Follow the instructions](https://viewcomponent.org/guide/generators.html) over on the ViewComponents' documentation to generate a new component.

### Folder structure

For simple components, the component and its template should appear in `app/components/` as shown below:

```
components
├── address_component.rb            # Component definition
└── address_component.html.erb      # HTML template
```

For more complex components, they should have their own folder. Using the above as an example, the folder structure would look like so:

```
components
├── address_component.rb            # Component definition
└── address_component
    ├── address_component.html.erb  # HTML template
    ├── address_component.js        # Optional: Stimulus controller
    └── address_component.scss      # Optional: Component-namespaced scss
```

### Linting

Components follow the same conventions as regular Ruby on Rails code. RuboCop gets run as part of our [pre-commit](https://github.com/geeksforsocialchange/PlaceCal/blob/main/package.json#L33-L36) hooks so any violations found will automatically be fixed. Whatever can't be fixed, you'll have to fix yourself :grinning:

### Testing

When testing components, please make sure that you write unit tests that only exercise the component's rendering logic. This means that no usage of VCR or an overly elaborate test data setup within the component test.

### Il8n

Localization is handled by the files in the `config/locales` directory.
