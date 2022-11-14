// Decorate any links that lead to non-federal sites with a disclaimer that clicking the link will take a user
// away from the current site

// When the page is fully loaded
jQuery(document).on('turbolinks:load', function() {

  // Find all links that lead away from a federal site (not current site or .gov or .mil)
  let links = jQuery('a').filter(function() {
    if (!this.href) {
      return false;
    }
    let url = new URL(this.href);
    return url.hostname != window.location.hostname && !url.hostname.match(/\.gov$|\.mil$/);
  });

  links.each(function() {

    // Add an icon showing that the link is to an external site; since we need a relative path to the image we
    // need to figure out what level we're at, and we do that by grabbing the src from a hidden version of the
    // image that's already on the page
    const image = document.createElement("img");
    image.src = jQuery('#leavingSiteImage').attr('src');
    this.insertAdjacentHTML('beforeEnd', ' '); // Add space before image
    this.appendChild(image);

    // When we click the link 1) stop the default behavior, 2) pop up a modal, and 3) point the Continue
    // button in the modal to the desired destination site
    this.addEventListener("click", function(event) {
      event.preventDefault();
      jQuery('#leavingSite').modal();
      jQuery('#leavingSite a.continue').attr('href', this.href);
    });
  });
});
