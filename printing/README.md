# Printing

## References

- [Configuring CUPS in RedHat][230718a]
- [CUPS CLI Administration][230718b]
- [man 8 lpadmin][230718c]
- [man 8 lpinfo][230718d]
- [man 8 cupsctl][230718e]


[230718a]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/deploying_different_types_of_servers/configuring-printing_deploying-different-types-of-servers
[230718b]: https://www.cups.org/doc/admin.html
[230718c]: https://www.cups.org/doc/man-lpadmin.html
[230718d]: https://www.cups.org/doc/man-lpinfo.html
[230718e]: https://www.cups.org/doc/man-cupsctl.html


## Adding a Printer

- Drivers for specific, non-IPP printers.

    ```
    lpinfo -m
    ```

- Connection methods for network connected printers.

    ```
    lpinfo -v
    ```

- Add a printer to the local list

    ```
    lpadmin -p <printer name> -E -v ipp://path/to/printer -m everywhere
    lpadmin -p <printer name> -E -v socket://path/to/printer -m <specific driver from lpinfo -m>
    ```

- Add a default printer to the local list

    ```
    lpadmin -d <printer name> -E -v ipp://path/to/printer -m everywhere
    lpadmin -d <printer name> -E -v socket://path/to/printer -m <specific driver from lpinfo -m>
    ```

- List printers in the local list

    ```
    lpinfo -l
    ```

