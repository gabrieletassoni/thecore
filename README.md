![Thecore Logo](https://github.com/gabrieletassoni/thecore_ui_layout_taris_website/raw/master/app/assets/images/logo.png)
# Thecore
**Thecore** is made of _ATOMS_ or, well, **Atomic Components**. 
The RoR App, the one made using _rails new_ command, will become just a container dependent on the _Atomic Components_ you need.
**Thecore** is a set of tools, best practices and guidelines aimed at creating bigger WebApps without focusing on how to do it.

**It's way better to focus on what to do than on how to do it, don't you think?**

## But... _What are ATOMS?_
 * **Self Contained engines:** the _Atomic Component_ must be developed following some guidelines which I'll document in the [Wiki](https://github.com/gabrieletassoni/thecore/wiki/Atomic_Component_Guidelines).
 * **Pluggable Components:** just make your RoR WebApp or another _Atomic Component_ depend on an _Atomic Component_ and it will inherit the funcitonalities of the _Atomic Component_, you don't need them anymore? just remove the dependency from Gemfile or gemspec and your WebApp will continue to work as before, but without the functionality provided by the _Atomic Component_
 * **Tested Components:** once tested for one application, they are tested for every other applications, no need to do regression tests on your app if it includes (say... depends) on functionalities provided by an Atomic Component.
 * **Easily Extandable:** _Atomic Components_ can be improved in their functionalities by adding new , but even better, they can be extended, without the need to touch well established code, in other _Atomic Components_ which will depend on the original one.
## Whys
As a freelance full-stack developer I always needed smart tools and methods to manage scalable projects. During the years I started to make choices, studying languages, patterns and technologies that were getting my attention because of their smartness.

Here is the efforts-turned-code, used and tested in different professional projects; thecore is just one of the  components, the most important, the foundation on which all the other atomic components grow. On github I'll put all of them, or, at least the general ones, the ones which doesn't have a strong characterization on a process peculiar to one of my customers.
## Philosphy
I always preferred to invest some more time in finding the best tool for what I need and compile a toolbox of helpful technologies, rather than start coding mindlessly. Thecore has grown and proved to be a time saver, it surely could be enhanced and as long as I keep using it for my day by day job, it will grow more, but if you feel that RoR, sane defaults, atomic engines (components) sound good to you, don't be scared to pull and make Thecore even more useful.
## Atomic Components
Here will be kept track of all the _Atomic Components_ available.
 * Utilities
    * [Thecore Thor Scripts](https://github.com/gabrieletassoni/thecore_thor_scripts): A set of scripts used to create new **Thecore** WebApps or new _Atomic Components_ and to transform an already created engine, into a **Thecore** _Atomic Component_
    * [Thecore Settings](https://github.com/gabrieletassoni/thecore_settings): If included in your projects it gives you an easy way of storing and retrieving settings for your app, completely integrated in Rails Admin thanks to [Rails Admin Settings](https://github.com/rs-pro/rails_admin_settings)
    * [Thecore Background Jobs](https://github.com/gabrieletassoni/thecore_background_jobs): Thecore common setup to send or schedule background jobs.
    * [Rails Admin Telnet Print](https://github.com/gabrieletassoni/rails_admin_telnet_print): Atomic Component used to Print to a set of predefined printers (using TCP/IP protocols such as ZPL).
    * Thecore Dataentry
        * [Thecore Dataentry Commons](https://github.com/gabrieletassoni/thecore_dataentry_commons): Common libraries used by other data entry components. This component allows dataentry by keyboard, keyboard emulation barcode scanners or websocket.
        * [Thecore Dataentry With Date Start and End](https://github.com/gabrieletassoni/thecore_dataentry_with_date_start_and_end): Atomic Component with UIs to perform barcode dataentry and confirm a start date and end date.
    * [Thecore Theme Taris](https://github.com/gabrieletassoni/thecore_theme_taris): Dependency package to pull all UI components and which provides some assets.
        * [Thecore UI Partial Snippets](https://github.com/gabrieletassoni/thecore_ui_partial_snippets): Some partials that can be used to simplify development.
        * [Rails Admin UI Dashboard Blocks](rails_admin_uihttps://github.com/gabrieletassoni/rails_admin_ui_dashboard_blocks_dashboard_blocks): I loved the concept of this dashboard since the very first moment I saw it, thus I integrated the assets from [Rollinbox](https://github.com/rollincode/rollinbox) into Thecore.
        * [Rails Admin UI Index Cards](https://github.com/gabrieletassoni/rails_admin_ui_index_cards): I like better a card layout for tables instead of the usual row one, it allows me to focus bettere on the info I need, this components brings right this, if included in your project, it replaces the tables with cards.
        * [Rails Admin Layout Taris](https://github.com/gabrieletassoni/rails_admin_ui_layout_taris): Main tweaks and assets to turn Rails Admin base layout to Thecore style.
        * [Rails Admin Layout Taris Website](https://github.com/gabrieletassoni/thecore_ui_layout_taris_website): Assets for the part of web app which resides outside Rails Admin scope.
## Partecipate
If you like to partecipate on this project, please do so; file bugs, pull and modify code, give suggestions...
## Support
Hire [me](mailto:gabriele.tassoni@gmail.com) as a full-stack developer for your RoR projects, I will use Thecore technology and show you how good it is. This is a straightforward way to support this project.
## Wiki
In the [wiki](https://github.com/gabrieletassoni/thecore/wiki) I'll put all the useful articles needed to fully understand the tool and the background theory.
## TO DO
 * **Document guidelines:** **Thecore** and the _Atomic Components_ are best used if you follow some guidelines, good programming tips. Some of the guidelines will be automated by some _rails [plugin] new_ templates and thor scripts, some other are just a matter of embracing sane defaults and methods.
 * **Code Cleanup**: move some views and assets in a dedicated **Thecore** Component
 * **Embrace Yarn completely**: rewrite some JS assets as installable packages and move them in a dedicated component
 * **Build a builder:** a web applications build upon **Thecore** and _Atomic Components_ will be released to aid in the process of creating your own application, it will assist in the process of defining the RoR WebApp or the building of a new Atomic Component.
