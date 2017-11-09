<?php

if(!isset($_POST['chair']) || !isset($_GET['checkintime'])) {
    header('Location: /passagier.php?balienummer='.$_GET['balienummer'].'&vluchtnummer='.$_GET['vluchtnummer'].'&passagiernummer='.$_GET['passagiernummer']);
}