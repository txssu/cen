# Cen Usage Guide for AI Agents

This guide defines the development and design standards used in Cen. It ensures consistency, clarity, and simplicity across all parts of the codebase. Follow these instructions strictly when building or updating any part of the app.

---

## Table of Contents

- [About this app](#about-this-app)
- [Principles](#principles)
- [Project Structure](#project-structure)
  - [Schemas](#schemas)
  - [Controllers](#controllers)
  - [LiveView Pages](#liveview-pages)
  - [Components](#components)
- [UI and Design Rules](#ui-and-design-rules)
  - [CSS and Tailwind](#css-and-tailwind)
  - [Icons](#icons)
  - [Accessibility and Responsiveness](#accessibility-and-responsiveness)
- [Routing and Text](#routing-and-text)
- [Documentation Standards](#documentation-standards)
- [Testing Guidelines](#testing-guidelines)
- [Elixir Usage](#elixir-usage)
- [OTP Usage](#otp-usage)
- [Setup and References](#setup-and-references)

---

## About this app

Cen is a job platform tailored for creative professionals and organizations. Inspired by hh.ru, Cen focuses on matching talent with opportunities in music, art, and other creative industries.

---

## Principles

- Always prefer the **simplest solution**. If something feels complex, refactor
- Favor **clarity and minimalism** in both code and UI
- Default to **Phoenix/LiveView** solutions. Use JavaScript only via `phx-hook` and only when unavoidable
- Follow design inspirations from **Apple, Linear, Vercel**
- Code must be **modular**, **tested**, and follow **SOLID** and **DRY** principles
- Favor **pattern matching**, **guards**, and **short functions**. Avoid nesting
- Prefer `:if` on elements instead of conditional blocks. E.g., <ul :if={@items}> instead of <%= if @items do %>
- Use `@impl ModuleName`, not `@impl true`
- **Never** nest multiple modules in the same file as it can cause cyclic dependencies

---

## Project Structure

### Schemas

- Use context-prefixed names: `Cen.Accounts.User`
- Include `@moduledoc` with a field table for SCHEMA modules only:
  ```
  | Field Name | Type | Description |
  ```
- Use `List`, not `Array` when defining a type in docs
- Default `array` fields to `[]`
- Add `timestamps(type: :utc_datetime)`
- Generate migrations along with schema changes using `mix ecto.gen.migration`

### Controllers

- Located in `lib/cen_web/controllers/`
- Use `use CenWeb, :controller`
- Match file/module names
- Add `@moduledoc` and `@doc` for each action

### LiveView Pages

- Located in `lib/cen_web/live/`
- Add `@moduledoc false`
- Place `render` at the top
- Use `use CenWeb, :live_view`
- Use socket's `assign/3` only for dynamic data. For static data, define a function instead
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- Remember anytime you use `phx-hook="MyHook"` and that js hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`
- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child
- LiveView streams are _not_ enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**
- LiveView streams _do not support counting or empty states_. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes like `<div class="hidden only:block">No tasks yet</div>`

### Components

- Shared components go in `lib/cen_web/components/`
- Import via `html_helpers` in `cen_web.ex`
- Use `Phoenix.Component.attr/3`
- Add `@moduledoc` and `@doc` with usage examples
- Add previews in `lib/cen_dev/ui_preview/`, register routes, and update `ui_preview_layout.ex`
- Use `<.text>` for all textual content
- Render slots via `{render_slot(@inner_block)}`
- Pass styling through `class=` props, not wrappers
- Don't write tests for UI/functional components
- Keep CSS in the component file, not in `globals.css` (we only add utilities there for reusable/shared styles)

---

## UI and Design Rules

### CSS and Tailwind

- Use **Tailwind v4**
- Avoid default colors — use tokens like `bg-zk-surface`
- Use `zk-` prefix for custom utilities
- Use `size-4` instead of `w-4 h-4`
- Only create custom utilities when we're often using the same styles
- Don't use `space-y-*` or `space-x-*` classes, instead use `gap-*`

### Accessibility and Responsiveness

- Responsive on mobile, tablet, desktop
- Follow accessibility best practices
- Use Tailwind breakpoints: `sm:`, `md:`, `lg:`, `xl:`
- Extend `globals.css`, don’t create new CSS files
- Keep animations minimal and non-distracting
- Prefer CSS/Tailwind for animations over JavaScript

---

## Routing and Text

- Use **Verified Routes** (`~p"/path"`), never use `Routes.page_path/2`
- Use **Gettext** for all strings
  - Do not hardcode text
  - Do not generate new translation files
  - Do not run `mix gettext.extract` (this will be done later)

---

## Documentation Standards

- Be clear, concise, objective
- Avoid vague terms like “secure” or “best practice”
- Use `@moduledoc` for modules
- Use `@doc` for functions, with examples
- Don’t prefix examples with `elixir`
- Combine multiple `on_mount` docs into one `@doc`

---

## Testing Guidelines

- Test file: same name as module + `_test`
- Use:
  - `Cen.DataCase` for data
  - `CenWeb.ConnCase` for web
- Fixtures in `test/support/fixtures/`
- Avoid `setup` for fixtures; call fixtures directly on each test
- Use `PhoenixTest` library - see [docs](./.github/copilot/llm_docs/phoenix_test.md)
- Use `Phoenix.Flash.get/2` (not `get_flash/2`)
- Don’t expose private functions for testing
- Run tests with `mix test`, not VSCode debugger
- Run `mix format` before committing
- Run `mix ci` after formatting to ensure code quality checks pass

---

## Elixir Usage

### Pattern Matching

- Use function heads and guards over `if`, `case`, `cond`
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or Enum functions

### Error Handling

- Use `{:ok, result}` and `{:error, reason}`
- Avoid raising for flow control
- Use `with` for chaining

### Data and Function Design

- Prefer `Stream` over `Enum` on large collections
- Don’t use `String.to_atom/1` on user input
- Prefer pattern matching, not indexing lists
- Name unused variables as `_name`, not `_`
- Use structs over maps for known shapes
- Prefer keyword lists for options
- Use descriptive function names
- Use `Oban` for background jobs
- Use **pipe-based query syntax** for clarity and composability
- Don't need to write `@spec` for functions but use structs in function signatures
- Elixir has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Ecto

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct

### Mix

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

---

## OTP Usage

### GenServer

- Keep state serializable
- Use `handle_continue/2` after init
- Cleanup in `terminate/2`
- Use `GenServer.call/3` with backpressure
- Use `GenServer.cast/2` for fire-and-forget

### Fault Tolerance

- Use supervisors with limits: `:max_restarts`, `:max_seconds`

### Tasks

- Use `Task.Supervisor`
- Use `Task.yield/2` or `Task.shutdown/2` for failures
- Use `Task.async_stream/3` with timeouts and backpressure

---

## Setup and References

- [Installation Guide](guides/installation.md)
- [Glossary](guides/glossary.md)
- [Directory Overview](guides/overview.md)

<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, us `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- claude-start -->
## claude usage
_Batteries-included Claude Code integration for Elixir projects_

[claude usage rules](deps/claude/usage-rules.md)
<!-- claude-end -->
<!-- claude:subagents-start -->
## claude:subagents usage
# Subagents Usage Rules

## Overview

Subagents in Claude projects should be configured via `.claude.exs` and installed using `mix claude.install`. This ensures consistent setup and proper integration with your project.

## Key Concepts

### Clean Slate Limitation
Subagents start with a clean slate on every invocation - they have no memory of previous interactions or context. This means:
- Context gathering operations (file reads, searches) are repeated each time
- Previous decisions or analysis must be rediscovered
- Consider embedding critical context directly in the prompt if repeatedly needed

### Tool Inheritance Behavior
When `tools` is omitted, subagents inherit ALL tools including dynamically loaded MCP tools. When specified:
- The list becomes static - new MCP tools won't be available
- Subagents without `:task` tool cannot delegate to other subagents
- Tool restrictions are enforced at invocation time, not definition time

## Configuration in .claude.exs

### Basic Structure

```elixir
%{
  subagents: [
    %{
      name: "Your Agent Name",
      description: "Clear description of when to use this agent",
      prompt: "Detailed system prompt for the agent",
      tools: [:read, :write, :edit],  # Optional - defaults to all tools
      usage_rules: ["package:rule"]    # Optional - includes specific usage rules
    }
  ]
}
```

### Required Fields

- **name**: Human-readable name (will be converted to kebab-case for filename)
- **description**: Clear trigger description for automatic delegation
- **prompt**: The system prompt that defines the agent's expertise

### Optional Fields

- **tools**: List of tool atoms to restrict access (defaults to all tools if omitted)
- **usage_rules**: List of usage rules to include in the agent's prompt

## References

- [Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents.md)
- [Claude Code Settings](https://docs.anthropic.com/en/docs/claude-code/settings.md)
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks.md)

<!-- claude:subagents-end -->
<!-- usage-rules-end -->
