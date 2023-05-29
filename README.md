![**Thecore** Logo](https://github.com/gabrieletassoni/thecore_ui_layout_taris_website/raw/master/app/assets/images/logo.png)

# Thecore

**Thecore** is made of _ATOMS_ or, well, **Atomic Components**. 
The RoR App, the one made using _rails new_ command, will become just a wrapper which depends only on the _Atomic Components_ you need.
**Thecore** is a set of tools, best practices and guidelines aimed at creating bigger WebApps without focusing on how to do it.

**It's way better to focus on what to do than on how to do it, don't you think?**

## But... _What are ATOMS?_

 * **Self Contained engines:** the _Atomic Component_ must be developed following some guidelines which are documented in this repository.
 * **Pluggable Components:** just make your RoR WebApp or another _Atomic Component_ depend on an _Atomic Component_ and it will inherit the funcitonalities of the _Atomic Component_, you don't need them anymore? just remove the dependency from Gemfile or gemspec and your WebApp will continue to work as before, but without the functionality provided by the _Atomic Component_ and without breaking the business logic.
 * **Tested Components:** once tested for one application, they are tested for every other applications, no need to do regression tests on your app if it includes (say... depends) on functionalities provided by an _Atomic Component_.
 * **Easily Extandable:** _Atomic Components_ can be improved in their functionalities by adding new ones, but even better, they can be extended in other _Atomic Components_ which will depend on the original one, without the need to touch well established code.

## Why

As a freelance full-stack developer I always needed smart tools and methods to manage scalable projects. During the years I started to make choices, studying languages, patterns and technologies that were getting my attention because of their smartness.

Here you can find this efforts-turned-code thing: **Thecore** has been used and tested in different professional projects and always proved smart enough to let me manage them even if they looked too big for one person; **Thecore** is just the most important aspect of all the ATOMS you can find in other repositories which follow **Thecore** [Guidelines](docs/SUMMARY.md), the foundation on which all the other atomic components grow. On github I'll put all of them, or, at least the general ones, the ones which doesn't have a strong characterization on a process peculiar to one of my customers.

## Philosphy

I always preferred to invest some more time in finding the best tool for what I need and compile a toolbox of helpful technologies, rather than start coding mindlessly. **Thecore** has grown and proved to be a time saver, it surely could be enhanced and as long as I keep using it for my day by day job, it will grow more, but if you feel that RoR, sane defaults, atomic engines (components) sounds good to you, don't be scared to pull and make **Thecore** even more useful.

# Thecore ATOMS

[Here](https://github.com/gabrieletassoni?tab=repositories&q=thecore&type=public&language=ruby&sort=name) you can find all **Thecore** ATOMS I published for public usage. They cover all the main aspects of a **Thecore** Application, from out of the box _APIs_, _Authentication_, _Backend UX_ and even interaction with Zebra RFID/Barcode scanners.

# Partecipate

If you like to partecipate on this project, please do so; file bugs, pull and modify code, give suggestions...

# Support

Hire [me](mailto:gabriele.tassoni@gmail.com) as a full-stack developer for your RoR projects, I will use **Thecore** technology and show you how good it is. This is a straightforward way to support this project.
