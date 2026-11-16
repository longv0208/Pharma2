package controller;

import dao.CategoryDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/** Public pharmacy information and policy page. */
@WebServlet(name = "AboutServlet", urlPatterns = {"/about"})
public class AboutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            CategoryDAO categoryDAO = new CategoryDAO();
            req.setAttribute("categories", categoryDAO.findAllActive());
        } catch (Exception e) {
            // Policies must remain readable even when the catalog is unavailable.
            getServletContext().log("About page category navigation unavailable", e);
        }
        req.getRequestDispatcher("/WEB-INF/views/about.jsp").forward(req, resp);
    }
}
