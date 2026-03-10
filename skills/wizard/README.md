# Wizard JSON Generator

Generates Sytex wizard JSON configurations. Wizards are step-by-step forms that collect user inputs and create objects (sites, tasks, network elements, WBS, clients, etc.) in Sytex.

## What it does

- Generates valid wizard JSON based on user requirements
- Supports all Sytex object types: Site, Task, NetworkElement, WorkStructure, Client, Project, Form, Code, Assignment, NetworkElementSite
- Supports all input types: text, number, date, options, related_object
- Handles dynamic filters between inputs, resolve, update_or_create, custom fields, and more

## Usage

Ask your AI coding agent to create a wizard JSON for your use case. For example:

> "Create a wizard that creates a site with a network element and a WBS"

The agent will generate the complete JSON configuration ready to be imported into Sytex.
