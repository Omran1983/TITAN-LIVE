document.addEventListener("DOMContentLoaded", () => {
  const links = document.querySelectorAll("a[data-scroll]");
  links.forEach((link) => {
    link.addEventListener("click", (e) => {
      const targetId = link.getAttribute("href");
      if (targetId && targetId.startsWith("#")) {
        const target = document.querySelector(targetId);
        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      }
    });
  });

  const path = window.location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll(`[data-page="${path}"]`).forEach((el) => {
    el.classList.add("active");
  });
});
