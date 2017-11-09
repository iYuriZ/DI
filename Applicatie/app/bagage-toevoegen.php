<?php

if(!isset($_POST['gewicht'])) {
    header('Location: /passagier.php?balienummer='.$_GET['balienummer'].'&vluchtnummer='.$_GET['vluchtnummer'].'&passagiernummer='.$_GET['passagiernummer']);
}

if(!isset($_GET['balienummer']) || !isset($_GET['vluchtnummer']) || !isset($_GET['passagiernummer']) || !isset($_POST['gewicht'])) {
    header('Location: /index.php');
}

require_once 'database.php';
$errorMessage = '';

try {
    $db = connectDatabase();
    $stmt = $db->prepare('INSERT INTO Object (passagiernummer, vluchtnummer, gewicht) VALUES (?, ?, ?)');
    $stmt->execute([
        $_GET['passagiernummer'],
        $_GET['vluchtnummer'],
        $_POST['gewicht']
    ]);
} catch (PDOException $pdoException) {
    $errorMessage = $pdoException->getMessage();
}

header('Location: /passagier.php?balienummer='.$_GET['balienummer'].'&vluchtnummer='.$_GET['vluchtnummer'].'&passagiernummer='.$_GET['passagiernummer'].'&bagage_error='.$errorMessage);