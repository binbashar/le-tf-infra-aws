resource "kubernetes_namespace" "monitoring" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "monitoring"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "external-dns"
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "vault"
  }
}

resource "kubernetes_namespace" "argo_cd" {
  metadata {
    labels = {
      environment = var.environment
    }

    name = "argo-cd"
  }
}

resource "kubernetes_namespace" "gatus" {
  metadata {
    labels = {
      environment                        = var.environment
      "goldilocks.fairwinds.com/enabled" = "true"
    }

    name = "gatus"
  }
}
