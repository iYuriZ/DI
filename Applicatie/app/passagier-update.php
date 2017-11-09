<?php

if(!isset($_POST['chair']) || !isset($_GET['checkintime'])) {
    header('Location: /passagier.php?balienummer='.$_GET['balienummer'].'&vluchtnummer='.$_GET['vluchtnummer'].'&passagiernummer='.$_GET['passagiernummer']);
}

if(!isset($_GET['balienummer']) || !isset($_GET['vluchtnummer']) || !isset($_GET['vluchtnummer']) || !isset($_GET['passagiernummer'])) {
    exit;
}

require_once 'database.php';

try {
    $db = connectDatabase();
    $stmt = $db->prepare('EXEC PROC_COUNT_PASSENGERS
                            @vluchtnr = ?,
                            @passagiernr = ?,
                            @balienr = ?,
                            @inchecktijd = ?,
                            @stoel = ?');
    $stmt->execute([
        $_GET['vluchtnummer'],
        $_GET['passagiernummer'],
        $_GET['balienummer'],
        $_POST['checkintime'],
        $_POST['chair']
    ]);
} catch(PDOException $pdoException) {
    $error = $pdoException->getMessage();
    header('Location: /passagier.php?balienummer='.$_GET['balienummer'].'&vluchtnummer='.$_GET['vluchtnummer'].'&passagiernummer='.$_GET['passagiernummer'].'&incheck_error='.$error);
}

header('Location: /zoek.php?balienummer='.$_GET['balienummer']);