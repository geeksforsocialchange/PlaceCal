# frozen_string_literal: true

# SVG Icons Helper
#
# Icons sourced from Lucide (https://lucide.dev)
# License: ISC License (https://github.com/lucide-icons/lucide/blob/main/LICENSE)
#
# Copyright (c) for portions of Lucide are held by Cole Bemis 2013-2022
# as part of Feather (MIT). All other copyright (c) for Lucide are held
# by Lucide Contributors 2022.

module SvgIconsHelper
  # rubocop:disable Layout/LineLength
  ICONS = {
    # Actions
    bell: 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9',
    car: 'M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2m6-2h6m-8 2a2 2 0 1 1-4 0 2 2 0 0 1 4 0zm12 0a2 2 0 1 1-4 0 2 2 0 0 1 4 0z',
    check: 'M5 13l4 4L19 7',
    clock: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z',
    cog: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z',
    edit: 'M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z',
    external_link: 'M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14',
    eye: 'M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z',
    eye_off: 'M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21',
    import: 'M12 3v12m0 0l4-4m-4 4l-4-4M2 17l.621 2.485A2 2 0 0 0 4.561 21h14.878a2 2 0 0 0 1.94-1.515L22 17',
    key: 'M2.586 17.414A2 2 0 0 0 2 18.828V21a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h1a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h.172a2 2 0 0 0 1.414-.586l.814-.814a6.5 6.5 0 1 0-4-4zM16.5 7a.5.5 0 1 0 0 1 .5.5 0 0 0 0-1z',
    loader: 'M21 12a9 9 0 11-6.219-8.56',
    logout: 'M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1',
    more_horizontal: 'M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z',
    more_vertical: 'M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z',
    plus: 'M12 4v16m8-8H4',
    swap: 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4',
    trash: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16',
    upload: 'M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12',
    x: 'M6 18L18 6M6 6l12 12',
    zoom: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v6m3-3H7',

    # Communication
    chat: 'M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z',
    link: 'M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1',
    link_off: 'M9 17H7A5 5 0 0 1 7 7 M15 7h2a5 5 0 0 1 4 8 M8 12h4 M2 2l20 20',
    mail: 'M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z',
    phone: 'M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z',

    # Content types
    article: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
    calendar: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z',
    event: 'M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z M13 5v2 M13 17v2 M13 11v2',
    neighbourhood: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0zM15 11a3 3 0 11-6 0 3 3 0 016 0z',
    partner: 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4',
    partnership: 'm11 17 2 2a1 1 0 1 0 3-3M14 14l2.5 2.5a1 1 0 1 0 3-3l-3.88-3.88a3 3 0 0 0-4.24 0l-.88.88a1 1 0 1 1-3-3l2.81-2.81a5.79 5.79 0 0 1 7.06-.87l.47.28a2 2 0 0 0 1.42.25L21 4m0-1 1 11h-2M3 3 2 14l6.5 6.5a1 1 0 1 0 3-3M3 4h8',
    photo: 'M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z',
    site: 'M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9',
    tag: 'M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z',
    user: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',

    # Location
    globe: 'M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9',
    location: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z',
    map_pin: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0zM15 11a3 3 0 11-6 0 3 3 0 016 0z',

    # Navigation
    arrow_down: 'M19 14l-7 7m0 0l-7-7m7 7V3',
    arrow_up: 'M5 10l7-7m0 0l7 7m-7-7v18',
    chevron_down: 'M19 9l-7 7-7-7',
    chevron_left: 'M15 19l-7-7 7-7',
    chevron_right: 'M9 5l7 7-7 7',
    chevron_up: 'M5 15l7-7 7 7',
    home: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6',

    # People
    user_add: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
    users: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z',

    # Resources
    book: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253',
    bug: 'M12 20v-9M14 7a4 4 0 0 1 4 4v3a6 6 0 0 1-12 0v-3a4 4 0 0 1 4-4zM14.12 3.88 16 2M21 21a4 4 0 0 0-3.81-4M21 5a4 4 0 0 1-3.55 3.97M22 13h-4M3 21a4 4 0 0 1 3.81-4M3 5a4 4 0 0 0 3.55 3.97M6 13H2m6-11 1.88 1.88M9 7.13V6a3 3 0 1 1 6 0v1.13',
    clipboard: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
    code: 'M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4',
    credit_card: 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z',
    desktop: 'M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z',
    list: 'M4 6h16M4 10h16M4 14h16M4 18h16',
    map: 'M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l5.447 2.724A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7',
    newspaper: 'M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z',

    # Social
    facebook: 'M18 2h-3a5 5 0 00-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 011-1h3z',
    instagram: 'M16 4H8a4 4 0 00-4 4v8a4 4 0 004 4h8a4 4 0 004-4V8a4 4 0 00-4-4zM12 15a3 3 0 110-6 3 3 0 010 6z',
    twitter: 'M23 3a10.9 10.9 0 01-3.14 1.53 4.48 4.48 0 00-7.86 3v1A10.66 10.66 0 013 4s-4 9 5 13a11.64 11.64 0 01-7 2c9 5 20 0 20-11.5a4.5 4.5 0 00-.08-.83A7.72 7.72 0 0023 3z',
    website: 'M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9',

    # Status / Alerts
    check_circle: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
    crown: 'M5 16L3 5l5.5 5L12 4l3.5 6L21 5l-2 11H5z',
    info: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    lightning: 'M13 10V3L4 14h7v7l9-11h-7z',
    lock: 'M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z',
    unlock: 'M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z',
    search_alert: 'M15.75 16.5a7.5 7.5 0 1 0-5.25 2.13M21 21l-4.35-4.35M11 8v2m0 4h.01',
    warning: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z',
    x_circle: 'M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z',

    # Forms - app/assets/images/icons/forms/
    checkbox: { path: 'M5.6,4 h12.8 a1.6,1.6,90,0,1,1.6,1.6 v12.8 a1.6,1.6,90,0,1,-1.6,1.6 h-12.8 a1.6,1.6,90,0,1,-1.6,-1.6 v-12.8 a1.6,1.6,90,0,1,1.6,-1.6', css_class: 'text-base-background' },
    checkbox_check: { path: 'M4.48,11.04 l5.2,5.2 l10.4,-10.4', stroke_linecap: 'butt', stroke_linejoin: 'butt', stroke_width: '5.36' },
    cross: { path: 'M19.932,7.2,16.548,3.768,12.3,8.004,8.052,3.768,4.668,7.2,8.904,11.4,4.668,15.6 l3.384,3.384,4.248,-4.236,4.248,4.236 L19.932,15.6,15.696,11.4 Z', stroke: 'none', fill: 'currentColor' },
    radio: { path: 'M12,1 A11,11,0,1,0,12.001,1', css_class: 'text-base-background' },
    radio_check: { path: 'M12,6 A6,6,0,1,0,12.001,6', stroke: 'none', fill: 'currentColor' },
    tick: { path: 'M20.328,8.532 l-3.804,-3.84 L10.8,10.428,8.076,7.644,4.272,11.484 l2.76,2.784,3.192,3.216 L20.328,8.532 Z', stroke: 'none', fill: 'currentColor' },

    # Triangles - app/assets/images/icons/arrows/
    triangle_up: { path: 'M0,18 l12,-12,12,12 Z', stroke: 'none', fill: 'currentColor' },
    triangle_down: { path: 'M0,6 l24,0,-12,12 Z', stroke: 'none', fill: 'currentColor' },
    triangle_left: { path: 'M18,0 l0,24,-12,-12 Z', stroke: 'none', fill: 'currentColor' },
    triangle_right: { path: 'M6,0 l12,12,-12,12 Z', stroke: 'none', fill: 'currentColor' },

    # Events - app/assets/images/icons/event
    event_date: { path: 'M18.5,17.056 C18.5,17.853,17.853,18.5,17.055,18.5 L6.945,18.5 C6.147,18.5,5.5,17.853,5.5,17.056 L5.5,11.278 C5.5,10.48,6.147,9.834,6.945,9.834 L17.055,9.834 C17.853,9.834,18.5,10.48,18.5,11.278 L18.5,17.056 Z M17.778,5.5 L17.778,4.778 C17.778,3.98,17.131,3.334,16.333,3.334 L15.611,3.334 C14.813,3.334,14.167,3.98,14.167,4.778 L14.167,5.5 L9.833,5.5 L9.833,4.778 C9.833,3.98,9.187,3.334,8.389,3.334 L7.667,3.334 C6.869,3.334,6.222,3.98,6.222,4.778 L6.222,5.5 C4.633,5.5,3.333,6.8,3.333,8.389 L3.333,17.778 C3.333,19.366,4.633,20.667,6.222,20.667 L17.778,20.667 C19.367,20.667,20.667,19.366,20.667,17.778 L20.667,8.389 C20.667,6.8,19.367,5.5,17.778,5.5 L17.778,5.5 Z', stroke: 'none', fill: 'currentColor' },
    event_duration: { path: 'M7.038,6.435 C8.209,6.968,9.935,7.536,12,7.536 C14.065,7.536,15.791,6.968,16.962,6.435 C16.545,8.902,14.482,10.782,12,10.782 C9.518,10.782,7.455,8.902,7.038,6.435 M14.215,12 C16.769,11.05,18.6,8.511,18.6,5.519 C18.6,4.093,16.743,3.202,14.423,2.845 C14.037,2.786,13.637,2.741,13.231,2.712 C12.825,2.682,12.413,2.667,12,2.667 C11.587,2.667,11.175,2.682,10.769,2.712 C10.363,2.741,9.963,2.786,9.577,2.845 C7.257,3.202,5.4,4.093,5.4,5.519 C5.4,8.511,7.232,11.05,9.785,12 C7.232,12.95,5.4,15.49,5.4,18.481 C5.4,22.284,18.6,22.284,18.6,18.481 C18.6,15.49,16.769,12.95,14.215,12', stroke: 'none', fill: 'currentColor' },
    event_place: { path: 'M12.027,12.91 C10.474,12.91,9.216,11.652,9.216,10.099 C9.216,8.546,10.474,7.288,12.027,7.288 C13.58,7.288,14.838,8.546,14.838,10.099 C14.838,11.652,13.58,12.91,12.027,12.91 M12.027,3.099 C8.161,3.099,5.027,6.233,5.027,10.099 C5.027,16.224,12.027,20.978,12.027,20.978 C12.027,20.978,19.027,16.224,19.027,10.099 C19.027,6.233,15.893,3.099,12.027,3.099', stroke: 'none', fill: 'currentColor' },
    event_repeats: { path: 'M24,12 L18.929,6.929 L13.859,12 L17.861,12 C17.861,15.237,15.237,17.861,12,17.861 L12,20.136 C16.463,20.136,20.136,16.463,20.136,12 L24,12 Z M12,6.139 L12,3.864 C7.537,3.864,3.864,7.537,3.864,12 L0,12 L5.071,17.071 L10.141,12 L6.139,12 C6.139,8.763,8.763,6.139,12,6.139', stroke: 'none', fill: 'currentColor' },
    event_time: { path: 'M13.324,12.478 L12.027,13.774 L11.747,13.495 L10.295,12.042 L9.037,10.784 L10.769,9.052 L12.027,10.309 L14.618,7.718 L16.351,9.451 L13.324,12.478 Z M12.027,4.042 C7.609,4.042,4.027,7.624,4.027,12.042 C4.027,16.46,7.609,20.042,12.027,20.042 C16.445,20.042,20.027,16.46,20.027,12.042 C20.027,7.624,16.445,4.042,12.027,4.042 L12.027,4.042 Z', stroke: 'none', fill: 'currentColor' }

    # Events - app/assets/images/icons/event/

  }.freeze
  # rubocop:enable Layout/LineLength

  SIZE_CLASSES = {
    '3' => 'size-3',
    '4' => 'size-4',
    '5' => 'size-5',
    '6' => 'size-6',
    '8' => 'size-8',
    '10' => 'size-10',
    '12' => 'size-12',
    '16' => 'size-16'
  }.freeze

  # Render an SVG icon
  # @param name [Symbol] Icon name from ICONS hash
  # @param size [String] Tailwind size class (e.g., "4", "5", "8")
  # @param css_class [String] Additional CSS classes
  # @param stroke_width [String] SVG stroke width (default: "2")
  # @return [String] HTML-safe SVG element
  # Size mapping to Tailwind classes (size-N for better JIT detection)
  def svg_icon(name, size: '5', css_class: '', stroke_width: '2')
    entry = ICONS[name.to_sym]
    return content_tag(:span, "[icon:#{name}]", class: 'text-error') unless entry

    # these (and css_class, stroke_width) can all be overriden by using a Hash instead of String value in ICONS
    # TODO: maybe add optional params for all of these?
    fill = 'none'
    stroke = 'currentColor'
    stroke_linecap = 'round'
    stroke_linejoin = 'round'
    viewbox = '0 0 24 24'

    if entry.is_a? Hash
      path = entry[:path]
      fill = entry[:fill] if entry[:fill].present?
      stroke = entry[:stroke] if entry[:stroke].present?
      stroke_linecap = entry[:stroke_linecap] if entry[:stroke_linecap].present?
      stroke_linejoin = entry[:stroke_linejoin] if entry[:stroke_linejoin].present?
      stroke_width = entry[:stroke_width] if entry[:stroke_width].present?
      css_class += " #{entry[:css_class]}" if entry[:css_class].present?
    else
      path = entry
    end

    size_class = SIZE_CLASSES[size.to_s] || ''
    # output no size_class or style if size<=0,
    style = if size.to_i.positive? && size_class.blank?
              "width: #{0.25 * size.to_f}rem; height: #{0.25 * size.to_f}rem;"
            else
              ''
            end
    classes = size_class
    classes += " #{css_class}" if css_class.present?

    # tailwind compat classes for non-admin frontend are in app/assets/stylesheets/temp_tailwind_compat.scss

    tag.svg(
      class: classes,
      fill: fill,
      stroke: stroke,
      viewBox: viewbox,
      'stroke-linecap': stroke_linecap,
      'stroke-linejoin': stroke_linejoin,
      'stroke-width': stroke_width,
      style: style
    ) do
      tag.path(
        d: path
      )
    end
  end

  # Shorthand method
  def icon(name, **)
    svg_icon(name, **)
  end
end
